// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

//NatSpec
/**
 * @title A Raffle Contract
 * @author Gavin Singh
 * @notice This contract is for creating a simple lottery
 * @dev This implements Chainlink VRF v2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playerLength, uint256 raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN, // 1
        CALCULATING // 2
    }

    /* State Variables */
    uint16 private constant requestConfirmations = 3;
    uint32 private constant numWords = 1;

    uint256 private immutable I_ENTRANCE_FEE;
    // @dev the duration of the lottery in seconds
    uint256 private immutable I_INTERVAL;
    bytes32 private immutable I_KEYHASH;
    uint256 private immutable I_SUBSCRIPTION_ID;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState; //start as open

    /*Events*/
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    /* @ dev_vrfCoordinator address of VRFCoordinator contract */

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        // adding the constructor of the parent contract
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        s_lastTimeStamp = block.timestamp;
        I_KEYHASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        s_raffleState = RaffleState.OPEN; // same as s_raffleState = RaffleState(0);
    }

    function enterRaffle() external payable {
        // require(msg.value >= I_ENTRANCE_FEE, "Not enough ETH!");
        // require(msg.value >= I_ENTRANCE_FEE, Raffle__SendMoreToEnterRaffle());
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender); // when you update storage, emit an event
    }

    // When should the winner be picked?
    /**
     * @dev This is the function that the Chainlink Keeper nodes will call to see if the lottery is ready to have a winner picked. The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is in an open state.
     * 3. The contract has ETH. (has players)
     * 4. Implicitly, your subscription is funded with LINK.
     * @return upkeepNeeded - true if its time to restart the raffle
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // upkeepNeeded defaults to false
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp >= I_INTERVAL);
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timeHasPassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "");
    }

    // Get a random number
    // Use that number to pick a random winner
    // Be automatically called

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        // Get random number
        // 1. Request random number

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient //adding the struct of VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: I_KEYHASH,
                subId: I_SUBSCRIPTION_ID,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    // 2. Get random number

    // ** CEI = Checks, Effects, Interactions ** //
    function fulfillRandomWords(
        uint256, //requestId,
        uint256[] calldata randomWords
    )
        internal
        override
    {
        // Checks
        // (none here) but eg. conditionals like if statements

        // Examples of randomWords:
        // s_player = 10, rng = 12, 12 % 10 = 2, but in reality rng = 5496083490568340956809, % 10 = 9

        // Effects - updating internal state variables
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner; // to help remember who the recent winner was
        s_raffleState = RaffleState.OPEN; // reset the raffle state
        s_players = new address payable[](0); // reset the players array
        s_lastTimeStamp = block.timestamp; // reset the last timestamp
        emit WinnerPicked(s_recentWinner);

        // Interactions - interacting with external contracts
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() public view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getPlayer(uint256 indexOfPlayer) public view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
