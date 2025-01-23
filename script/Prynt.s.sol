// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Inbox} from "infernet-sdk/Inbox.sol";
import {Fee} from "infernet-sdk/payments/Fee.sol";
import {Registry} from "infernet-sdk/Registry.sol";
import {Reader} from "infernet-sdk/utility/Reader.sol";
import {Coordinator} from "infernet-sdk/Coordinator.sol";
import {EIP712Coordinator} from "infernet-sdk/EIP712Coordinator.sol";
import {WalletFactory} from "infernet-sdk/payments/WalletFactory.sol";

contract PryntScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address deployerAddress = vm.envAddress("DEPLOYER");
        uint64 initialNonce = vm.getNonce(deployerAddress);
        address initialFeeRecipient = deployerAddress;
        uint16 initialFee = 500; // 5%

        // Precompute addresses for {Coordinator, Inbox, Reader}
        address coordinatorAddress = vm.computeCreateAddress(
            deployerAddress,
            initialNonce + 1
        );
        address inboxAddress = vm.computeCreateAddress(
            deployerAddress,
            initialNonce + 2
        );
        address readerAddress = vm.computeCreateAddress(
            deployerAddress,
            initialNonce + 3
        );
        address feeAddress = vm.computeCreateAddress(
            deployerAddress,
            initialNonce + 4
        );
        address walletFactoryAddress = vm.computeCreateAddress(
            deployerAddress,
            initialNonce + 5
        );

        // Initialize new registry
        Registry registry = new Registry(
            coordinatorAddress,
            inboxAddress,
            readerAddress,
            feeAddress,
            walletFactoryAddress
        );

        // Initialize new EIP712Coordinator
        EIP712Coordinator coordinator = new EIP712Coordinator(registry);

        // Initialize new Inbox
        Inbox inbox = new Inbox(registry);

        // Initialize new Reader
        Reader reader = new Reader(registry);

        // Initialize new Fee
        Fee fee = new Fee(initialFeeRecipient, initialFee);

        // Initialize new WalletFactory
        WalletFactory walletFactory = new WalletFactory(registry);

        console.log("Using protocol fee: 5%");
        console.log("Deployed Registry: ", address(registry));
        console.log("Deployed EIP712Coordinator: ", address(coordinator));
        console.log("Deployed Inbox: ", address(inbox));
        console.log("Deployed Reader: ", address(reader));
        console.log("Deployed Fee: ", address(fee));
        console.log("Deployed WalletFactory: ", address(walletFactory));

        vm.stopBroadcast();
    }
}
