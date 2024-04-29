// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFooDriverRegistry {
    error NotSuperAdmin();
    error NotUpgrader();
    struct OrderParams {
        string storeId;
        string orderId;
        address customerAddress;
        uint256 amount;
        uint256 deliveryAmount;
        uint256 storeGuaranteeDepositPercent;
        uint256 customerGuaranteeDepositPercent;
        uint256 courierGuaranteeDepositPercent;
        uint256 appCommissionPercent;
        uint256 weightGoodsDepositAmount;
    }

}
