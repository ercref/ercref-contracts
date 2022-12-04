// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {Test} from "./utils/Test.sol";
import {FiftyFifty, IFiftyFifty, IFiftyFiftyEvents, IFiftyFiftyTypes} from "../FiftyFifty.sol";

contract FiftyFiftyTest is Test, IFiftyFiftyEvents, IFiftyFiftyTypes {
    FiftyFifty private ff;

    address internal alice;
    address internal bob;

    function setUp() public {
        ff = new FiftyFifty();

        uint256 userNum = 2;
        address payable[] memory users = new address payable[](userNum);
        bytes32 nextUser = keccak256(abi.encodePacked("user address"));
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = payable(address(uint160(uint256(nextUser))));
            nextUser = keccak256(abi.encodePacked(nextUser));
            vm.deal(user, 100 ether);
            users[i] = user;
        }

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
    }

    function testOk_commit(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);

        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        assertEq(ff.getGame(1).committer, alice);
        assertEq(ff.getGame(1).commitment, commitment);
        assertEq(ff.getGame(1).bet, bet);
    }

    function testOk_gameIncrement(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance / 2;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        assertEq(ff.getGameCount(), 1);

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(2, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        assertEq(ff.getGameCount(), 2);
    }

    function testOk_cancel(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        vm.expectEmit(true, true, true, true);
        emit GameEnded(1, GameEndReason.CANCEL, alice);
        vm.prank(alice);
        ff.cancelBet(1);

        assertTrue(ff.getGame(1).ended);
    }

    function testOk_matchBetAmountTooLow(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        vm.expectRevert("bet amount does not match");
        vm.prank(bob);
        ff.matchBet{value: bet - 1}(1, !_choice);
    }

    function testOk_revealWin(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        // bob chooses wrong choice
        vm.expectEmit(true, true, true, true);
        emit BetMatched(1, !_choice, bob);
        vm.prank(bob);
        ff.matchBet{value: bet}(1, !_choice);

        assertEq(ff.getGame(1).guesser, bob);

        vm.expectEmit(true, true, true, true);
        emit GameEnded(1, GameEndReason.REVEAL, alice);
        vm.prank(alice);
        ff.reveal(1, _choice, _salt);

        assertTrue(ff.getGame(1).ended);
        assertEq(alice.balance, bet * 2);
    }

    function testOk_revealLose(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        // bob chooses right choice
        vm.expectEmit(true, true, true, true);
        emit BetMatched(1, _choice, bob);
        vm.prank(bob);
        ff.matchBet{value: bet}(1, _choice);

        assertEq(ff.getGame(1).guesser, bob);

        vm.expectEmit(true, true, true, true);
        emit GameEnded(1, GameEndReason.REVEAL, bob);
        vm.prank(alice);
        ff.reveal(1, _choice, _salt);

        assertTrue(ff.getGame(1).ended);
        assertEq(bob.balance, bet * 2);
    }

    function testOk_timeout(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        // bob chooses right choice
        vm.expectEmit(true, true, true, true);
        emit BetMatched(1, _choice, bob);
        vm.prank(bob);
        ff.matchBet{value: bet}(1, _choice);

        assertEq(ff.getGame(1).guesser, bob);

        vm.warp(block.timestamp + 7 days + 1);

        vm.expectEmit(true, true, true, true);
        emit GameEnded(1, GameEndReason.TIMEOUT, bob);
        vm.prank(bob);
        ff.timeoutBet(1);

        assertTrue(ff.getGame(1).ended);
        assertEq(bob.balance, bet * 2);
    }

    function testOk_timeoutBeforeExpire(bool _choice, bytes32 _salt) public payable {
        bytes32 commitment = keccak256(abi.encodePacked(_choice, _salt));
        uint256 bet = alice.balance;

        vm.expectEmit(true, true, true, true);
        emit BetPlaced(1, bet, alice, commitment);
        vm.prank(alice);
        ff.commit{value: bet}(commitment);

        // bob chooses right choice
        vm.expectEmit(true, true, true, true);
        emit BetMatched(1, _choice, bob);
        vm.prank(bob);
        ff.matchBet{value: bet}(1, _choice);

        assertEq(ff.getGame(1).guesser, bob);

        vm.expectRevert("game hasn't expired");
        vm.prank(bob);
        ff.timeoutBet(1);
    }
}
