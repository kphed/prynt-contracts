// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Inbox} from "infernet-sdk/Inbox.sol";
import {Fee} from "infernet-sdk/payments/Fee.sol";
import {Registry} from "infernet-sdk/Registry.sol";
import {Reader} from "infernet-sdk/utility/Reader.sol";
import {Coordinator} from "infernet-sdk/Coordinator.sol";
import {EIP712Coordinator} from "infernet-sdk/EIP712Coordinator.sol";
import {WalletFactory} from "infernet-sdk/payments/WalletFactory.sol";

contract InfernetSDK is Test {
    Registry public immutable registry;
    EIP712Coordinator public immutable coordinator;
    Inbox public immutable inbox;
    Reader public immutable reader;
    Fee public immutable fee;
    WalletFactory public immutable walletFactory;

    constructor() {
        address deployerAddress = address(this);
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
        registry = new Registry(
            coordinatorAddress,
            inboxAddress,
            readerAddress,
            feeAddress,
            walletFactoryAddress
        );
        coordinator = new EIP712Coordinator(registry);
        inbox = new Inbox(registry);
        reader = new Reader(registry);
        fee = new Fee(initialFeeRecipient, initialFee);
        walletFactory = new WalletFactory(registry);
    }
}
