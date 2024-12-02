// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EternalContract{
    mapping(address => Player) addPlayer;
    address payable public contractAddr;
    address public owner;
    receive() external payable { }
    constructor() {
        owner = msg.sender;
        contractAddr = payable(address(this));
    }

    struct Player{
        Hands playerHands;
        uint balance;
        bytes32 hands;
        bytes32 committed;
        bool isActive;
    }

    enum Hands{
        rock,
        paper,
        scissor
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // function deposit() external payable{
    //     require(msg.value >= 0,"Invalid Value");
    //     payable(address(this)).transfer(msg.value);
    // }

    function deposit()external payable returns(bool){
        require( msg.value>= 0, "Invalid Value");
        return contractAddr.send(msg.value);
    }

    function transfer(uint amount, address payable _to)external onlyOwner payable returns(bool){
        require(address(this).balance >= amount, "Insufficient Funds");
        return _to.send(amount);
    }

    function registerPlayer(address _player)external{
        addPlayer[_player].isActive = true;
    }

    function getPlayerStatus(address _player) external view returns(bool){
        return (addPlayer[_player].isActive);
    }

    function updateBalance(address _player, uint _amount) external{
        addPlayer[_player].balance += _amount;
     }

     function getBalance(address _player) external view returns (uint){
        return (addPlayer[_player].balance);
    }

    function _chosenSign(address player, bytes32 _chosen ) external{
        addPlayer[player].committed = _chosen;
    }

    function _getChoosenSign(address player) external view returns(bytes32) {
        return addPlayer[player].committed;
    }

    function chosenHand(address player, uint _playerHands) external {
        if(_playerHands == 0){
            addPlayer[player].hands = keccak256("rock");
        }else if(_playerHands == 1){
            addPlayer[player].hands = keccak256("paper");
         }else if(_playerHands ==2){
             addPlayer[player].hands = keccak256("scissor");
        }
    }

    function getChosenHand(address player) external view returns(bytes32){
        return addPlayer[player].hands;
    }

    function matchReward(address _playerA, address _playerB) external {
        addPlayer[_playerA].balance += 98;
        addPlayer[_playerB].balance -=  102;
    }

    function getPlayerInformation(address _player) external view returns(Player memory){
        return (addPlayer[_player]);
    }

}