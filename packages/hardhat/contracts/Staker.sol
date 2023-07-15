// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    // Stake event (to be used in frontend)
    event Stake(address indexed user, uint256 ethAmount);

    // Tracking individual 'balances' with a mapping
    mapping(address => uint256) public userBalances;

    uint256 public constant threshold = 1 ether;

    // Staking deadline, post this user are allowed to execute() or withdraw()
    uint256 public deadline = block.timestamp + 1 days;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        // update user's balance according to his stake
        userBalances[msg.sender] += msg.value;

        // emitting stake event indicating user staked successfully
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() external {
        require(timeLeft() == 0, "Deadline not yet passed");

        uint256 contractBalance = address(this).balance;

        // check if this contract has reach ETH threshold limit
        require(contractBalance >= threshold, "Threshold not reached");

        // transfers this contract whole ether balance to exampleExternal Contract
        (bool sent, ) = address(exampleExternalContract).call{
            value: contractBalance
        }("");
        require(sent, "Sending ether failed");
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw(address payable user) external {
        uint256 userBalance = userBalances[user];

        // Allows withdrawals if the deadline has passed
        require(timeLeft() == 0, "Deadline not yet passed");

        // check if the user has balance to withdraw
        require(userBalance != 0, "No balance to withdraw");

        // reset the balance of the user before transferring funds to prevent re-entrancy attack
        userBalances[user] = 0;

        // withdraws user's balance
        user.transfer(userBalance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return block.timestamp > deadline ? 0 : deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
