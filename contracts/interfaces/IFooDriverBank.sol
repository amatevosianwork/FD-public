// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IFooDriverBank {
    // Events
    event PaymentReceived(string orderId, uint256 amount, address customer, address store);
    event PaymentReleased(string orderId, address to, uint256 amount);
    event RefundProcessed(string orderId, address to, uint256 amount);
    event CommissionsWalletUpdated(address newWallet);

    error OrderAlreadyRefunded();
    error OrderAlreadyCompleted();
    error OrderAlreadyExists();
    error OrderDoesNotExist();
    error OrderIsPending();

    function lockCustomerPayment(uint256 _customerLockAmount, address _customerAddress) external returns (bool);

    function lockStorePayment(uint256 _storeLockAmount, address _storeAddress) external returns (bool);

    function lockCourierPayment(string memory _orderId, address _storeAddress, address _courierAddress) external returns (bool);

    function unlockCourierPayment(string memory _orderId, address _storeAddress) external  returns (bool);

    function releasePayment(address _storeAddress, string memory _orderId, uint256 _weightGoodsReturn) external;

    function setCommissionWallet(address _newCommissionWallet) external;

    function refundPayment(
        address _storeAddress,
        string memory _orderId,
        bool toCustomer,
        bool toStore,
        bool toCourier
    ) external;

    function withdrawERC20Token(address _tokenAddress, uint256 _amount, address _to) external;

}
