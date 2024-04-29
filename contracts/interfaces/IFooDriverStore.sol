// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFooDriverStore {
    error NotRegistry();
    error InvalidCustomerAddress();
    error OrderAlreadyExists();
    error OrderDoesNotExist();
    error OrderNotPending();
    error OrderNotConfirmed();
    error OrderNotInDelivery();
    enum OrderStatus {
        Pending,
        Confirmed,
        InDelivery,
        Completed,
        Refunded
    }
    struct Order {
        string id;
        address customerAddress;
        address storeAddress;
        address courierAddress;
        uint256 amount;
        uint256 deliveryAmount;
        OrderStatus status;
        uint256 customerGuaranteeDepositPercent;
        uint256 storeGuaranteeDepositPercent;
        uint256 courierGuaranteeDepositPercent;
        uint256 appCommissionPercent;
        uint256 weightGoodsDepositAmount;
    }

    function addCourierToOrder(string memory _orderId, address _courierAddress) external;
    function changeCourierInOrder(string memory _orderId, address _courierAddress) external;
    function createOrder(
        string memory _orderId,
        address _customerAddress,
        uint256 _amount,
        uint256 _deliveryAmount,
        uint256 _storeGuaranteeDepositPercent,
        uint256 _customerGuaranteeDepositPercent,
        uint256 _courierGuaranteeDepositPercent,
        uint256 _appCommissionPercent,
        uint256 _weightGoodsReturn
    ) external returns (string memory orderId);

    function confirmOrder(string memory _orderId) external returns (string memory orderId);

    function refundOrder(string memory _orderId,  bool toCustomer,
        bool toStore,
        bool toCourier) external;

    function releaseOrder(string memory _orderId, uint256 _weightGoodsReturn) external;

    function getOrderById(string memory _orderId) external view returns (Order memory);

    function withdrawERC20Token(address _tokenAddress, uint256 _amount, address _to) external;

}