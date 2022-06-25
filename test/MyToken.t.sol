// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";

import "../src/MyToken.sol";

contract ContractTest is Test {

    MyToken token;
    address sky = vm.addr(0x1);
    address stajer = vm.addr(0x2);

    function setUp() public {
        token = new MyToken("YODA", "YD");
    }

    function testExample() external {
        assertEq("YODA", token.name());
    }

    // Basic Testing

    function testMint() public {
        token.mint(sky, 2e18);
        assertEq(token.totalSupply(), token.balanceOf(sky));
    }

    function testBurn() public {
        token.mint(sky, 10e18);
        assertEq(token.balanceOf(sky), 10e18);

        token.burn(sky, 8e18);

        assertEq(token.totalSupply(), 2e18);
        assertEq(token.balanceOf(sky), 2e18);
    }

    function testApprove() public {
        assertTrue(token.approve(sky, 1e18));
        assertEq(token.allowance(address(this), sky), 1e18);
    }

    function testIncreaseAllowance() external {
        assertEq(token.allowance(address(this), sky), 0);
        assertTrue(token.increaseAllowance(sky, 2e18));
        assertEq(token.allowance(address(this), sky), 2e18);
    }

    // Advanced Testing
    
    // you can arbritrarily change the msg.sender value via prank(), startPrank(), and stopPrank()

    function testTransfer() external {
        testMint();
        // all the calls made b/w startPrank() and stopPrank() will be made from the specified address
        vm.startPrank(sky);
        token.transfer(stajer, 0.5e18);
        assertEq(token.balanceOf(sky), 1.5e18);
        vm.stopPrank();
    }

    function testTransferFrom() external {
        testMint();
        // prank() ensures that a call made after it is called is made from a specified address
        vm.prank(sky);
        token.approve(address(this), 1e18);
        assertTrue(token.transferFrom(sky, stajer, 0.7e18));
        assertEq(token.allowance(sky, address(this)), 1e18 - 0.7e18);
        assertEq(token.balanceOf(sky), 2e18 - 0.7e18);
        assertEq(token.balanceOf(stajer), 0.7e18);
    }

    // Failure Tests

    function testFailMintToZero() external {
        token.mint(address(0), 1e18);
    }

    function testFailBurnFromZero() external {
        token.burn(address(0), 1e18);
    }

    function testFailBurnInsufficientBalance() external {
        testMint();
        vm.prank(sky);
        token.burn(sky, 3e18);
    }

    function testFailApproveToZeroAddress() external {
        token.approve(address(0), 1e18);
    }

    function testFailApproveFromZeroAddress() external {
        vm.prank(address(0));
        token.approve(sky, 1e18);
    }

    function testFailTransferToZeroAddress() external {
        testMint();
        vm.prank(sky);
        token.transfer(address(0), 1e18);
    } 

    function testFailTransferFromZeroAddress() external {
        testBurn();
        vm.prank(address(0));
        token.transfer(sky, 1e18);
    }

    function testFailTransferInsufficientBalance() external {
        testMint();
        vm.prank(sky);
        token.transfer(stajer, 3e18);
    } 

     function testFailTransferFromInsufficientApprove() external {
        testMint();
        vm.prank(sky);
        token.approve(address(this), 1e18);
        token.transferFrom(sky, stajer, 2e18);
    } 

     function testFailTransferFromInsufficientBalance() external {
        testMint();
        vm.prank(sky);
        token.approve(address(this), type(uint).max);

        token.transferFrom(sky, stajer, 3e18);
    } 

    // Fuzz Tests

    // Fuzz Testing / Fuzzing: An automated software testing technique that involves providing invalid, unexpected, or random data as inputs to a computer program

    // By default, fuzzing will run each testcase 256 times with random inputs. If you want increase the this runs then just add fuzz_runs = <inputNumber> in foundry.toml.

    function testFuzzMint(address to, uint256 amount) external {
        vm.assume( to != address(0));
        token.mint(to, amount);
        assertEq(token.totalSupply(), token.balanceOf(to));
    }

    function testFuzzBurn(address from, uint256 mintAmount, uint256 burnAmount) external {
        vm.assume(from != address(0));
        burnAmount = bound(burnAmount, 0, mintAmount);

        token.mint(from, mintAmount);
        token.burn(from, burnAmount);
        assertEq(token.totalSupply(), mintAmount - burnAmount);
        assertEq(token.balanceOf(from), mintAmount - burnAmount);
    }

    function testFuzzApprove(address to, uint256 amount) external {
        vm.assume(to != address(0));
        assertTrue(token.approve(to, amount));
        assertEq(token.allowance(address(this), to), amount);
    }

}
