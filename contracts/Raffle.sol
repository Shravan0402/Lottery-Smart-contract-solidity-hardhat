// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughTockensEntered();
error Raffle__TransferFailed();
error Raffle__CalculatingResults();
error Raffle__UpKeepNotNeeded();

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum Rafflestate {
        OPEN,
        CALCULATING
    }

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address payable private s_recentWinner;
    Rafflestate private s_RaffleState;
    uint256 private s_lastTimeStamp;
    uint256 private s_interval;

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event winnerPicked(address indexed winner);

    constructor(
        address VRFCoordinatorV2,
        uint256 _i_entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(VRFCoordinatorV2) {
        i_entranceFee = _i_entranceFee;
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_RaffleState = Rafflestate.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_interval = interval;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughTockensEntered();
        }
        if (s_RaffleState != Rafflestate.OPEN)
            revert Raffle__CalculatingResults();
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public override returns(
        bool upkeepNeeded,
        bytes memory /*performData*/
    ) {
        bool isOpen = (Rafflestate.OPEN == s_RaffleState);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > s_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        bool upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /*performData*/) external override{
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) revert Raffle__UpKeepNotNeeded();
        s_RaffleState = Rafflestate.CALCULATING;
        uint256 requestId = vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords)
        internal
        override
    {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_RaffleState = Rafflestate.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{
            value: (address(this).balance * 98) / 100
        }("");
        if (!success) revert Raffle__TransferFailed();
        emit winnerPicked(recentWinner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

}