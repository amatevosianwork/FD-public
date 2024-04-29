// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFooDriverStore} from "./interfaces/IFooDriverStore.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IFooDriverBank} from "./interfaces/IFooDriverBank.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title FooDriverBank
 * @dev Contract to manage financial transactions within the FooDriver platform, handling secure locking and releasing of funds.
 * @notice This contract supports upgradeability and uses OpenZeppelin's UUPS pattern.
 */
contract FooDriverBank is Initializable, UUPSUpgradeable, IFooDriverBank {
    IERC20 public token;
    address public registry;
    address public commissionsWallet;

    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    bytes32 public constant STORE_ROLE = keccak256("STORE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Custom errors for access control
    error NotStore();
    error NotRegistry();
    error NotUpgrader();
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    /**
        * @dev Initializes the contract with essential addresses and setups the upgradable pattern.
     * @param initialAuthority Address with registry role management capability.
     * @param tokenAddress ERC20 token used for transactions.
     * @param commissionsReceiver Address where commission funds are sent.
     */
    function initialize(address initialAuthority, address tokenAddress, address commissionsReceiver) initializer public {
        __UUPSUpgradeable_init();
        token = IERC20(tokenAddress);
        registry = initialAuthority;
        commissionsWallet = commissionsReceiver;

    }




    modifier onlyStore() {

        if (!IAccessControl(registry).hasRole(STORE_ROLE, msg.sender)) {
            revert NotStore();
        }
        _;
    }


    modifier onlyRegistry() {
        if (!IAccessControl(registry).hasRole(REGISTRY_ROLE, msg.sender)) {
            revert NotRegistry();
        }
        _;
    }
    modifier onlyUpgrader() {
        if (!IAccessControl(registry).hasRole(UPGRADER_ROLE, msg.sender)) {
            revert NotUpgrader();
        }
        _;
    }
    /**
       * @notice Sets a new address for the commissions wallet.
     * @dev Accessible only by an account with the `REGISTRY_ROLE`.
     * @param _newCommissionWallet New wallet address for receiving commissions.
     */
    function setCommissionWallet(address _newCommissionWallet) external onlyRegistry {
        commissionsWallet = _newCommissionWallet;
        emit CommissionsWalletUpdated(_newCommissionWallet);
    }
/**
     * @notice Locks a specified amount of customer funds in the contract.
     * @dev Requires the calling account to have the `STORE_ROLE`.
     * @param _customerLockAmount Amount to lock.
     * @param _customerAddress Address of the customer whose funds are being locked.
     * @return True if funds are successfully transferred.
     */
    function lockCustomerPayment(uint256 _customerLockAmount, address _customerAddress) external onlyStore returns (bool) {
        require(token.transferFrom(_customerAddress, address(this), _customerLockAmount), "Transfer failed from customer");
        return true;
    }
    /**
   * @notice Locks a specified amount of store funds in the contract.
     * @dev Requires the calling account to have the `STORE_ROLE`.
     * @param _storeLockAmount Amount to lock.
     * @param _storeAddress Address of the store whose funds are being locked.
     * @return True if funds are successfully transferred.
     */
    function lockStorePayment(uint256 _storeLockAmount, address _storeAddress) external onlyStore returns (bool) {
        require(token.transferFrom(_storeAddress, address(this), _storeLockAmount), "Transfer failed from store");
        return true;
    }
    /**
       * @notice Locks payment for a courier based on an order's details.
     * @dev Callable only by accounts with the `STORE_ROLE`.
     * @param _orderId Order identifier to lock funds against.
     * @param _storeAddress Address of the store involved in the order.
     * @param _courierAddress Address of the courier whose funds are being locked.
     * @return True if funds are successfully transferred.
     */
    function lockCourierPayment(string memory _orderId, address _storeAddress, address _courierAddress) external onlyStore returns (bool) {
        IFooDriverStore.Order memory lockOrder = IFooDriverStore(_storeAddress).getOrderById(_orderId);
        uint256 courierGuaranteeLockAmount = lockOrder.amount * lockOrder.courierGuaranteeDepositPercent / 100;
        uint256 courierFinalLock = courierGuaranteeLockAmount + lockOrder.amount;
        require(token.transferFrom(_courierAddress, address(this), courierFinalLock), "Transfer failed from courier");
        return true;
    }
    /**
        * @notice Unlocks and transfers the locked payment to the courier once delivery is confirmed.
     * @dev Callable only by accounts with the `STORE_ROLE`.
     * @param _orderId Order identifier for which payment is being unlocked.
     * @param _storeAddress Address of the store involved in the order.
     * @return True if funds are successfully transferred.
     */
    function unlockCourierPayment(string memory _orderId, address _storeAddress) external onlyStore returns (bool) {
        IFooDriverStore.Order memory lockOrder = IFooDriverStore(_storeAddress).getOrderById(_orderId);
        uint256 courierGuaranteeLockAmount = lockOrder.amount * lockOrder.courierGuaranteeDepositPercent / 100;
        uint256 courierFinalLock = courierGuaranteeLockAmount + lockOrder.amount;
        require(token.transferFrom(address(this), lockOrder.courierAddress, courierFinalLock), "Transfer failed from bank");
        return true;
    }
    /**
       * @notice Releases payment to the store and the customer based on the order status.
     * @dev Callable only by accounts with the `STORE_ROLE`.
     * @param _storeAddress Address of the store involved in the transaction.
     * @param _orderId Order identifier for which payment is being released.
     * @param _weightGoodsReturn Additional amount to be returned to the customer.
     */
    function releasePayment(address _storeAddress, string memory _orderId, uint256 _weightGoodsReturn) external onlyStore {
        IFooDriverStore.Order memory releaseOrder = IFooDriverStore(_storeAddress).getOrderById(_orderId);
        if (releaseOrder.customerAddress == address(0)) {
            revert OrderDoesNotExist();
        }
        if (releaseOrder.status == IFooDriverStore.OrderStatus.Refunded) {
            revert OrderAlreadyRefunded();
        }
        if (releaseOrder.status == IFooDriverStore.OrderStatus.Completed) {
            revert OrderAlreadyCompleted();
        }
        if (releaseOrder.status == IFooDriverStore.OrderStatus.Pending) {
            revert OrderIsPending();
        }
        if (releaseOrder.status == IFooDriverStore.OrderStatus.InDelivery || releaseOrder.status == IFooDriverStore.OrderStatus.Confirmed) {
            uint256 customerReleaseAmount = releaseOrder.amount * releaseOrder.customerGuaranteeDepositPercent / 100 + _weightGoodsReturn;
            uint256 storeReleaseAmount = releaseOrder.amount * releaseOrder.storeGuaranteeDepositPercent / 100 + releaseOrder.amount;
            IERC20(token).transfer(releaseOrder.customerAddress, customerReleaseAmount);
            IERC20(token).transfer(releaseOrder.storeAddress, storeReleaseAmount);
            uint256 appProfits = releaseOrder.amount * releaseOrder.appCommissionPercent / 100;
            if (releaseOrder.courierAddress != address(0)) {
                uint256 courierProfits = releaseOrder.amount / 100;
                uint256 deliveryCost = releaseOrder.deliveryAmount;
                uint256 courierReleaseAmount = (releaseOrder.amount * releaseOrder.courierGuaranteeDepositPercent / 100) + releaseOrder.amount + courierProfits + deliveryCost;
                IERC20(token).transfer(releaseOrder.courierAddress, courierReleaseAmount);
                appProfits -= courierProfits;
            }
            IERC20(token).transfer(commissionsWallet, appProfits);
        }

    }
    /**
      * @notice Refunds the locked payments back to the customer, store, or courier based on order details and caller's decision.
     * @dev Callable only by accounts with the `STORE_ROLE`.
     * @param _storeAddress Address of the store involved in the order.
     * @param _orderId Order identifier for the refund process.
     * @param toCustomer Boolean flag to refund to the customer.
     * @param toStore Boolean flag to refund to the store.
     * @param toCourier Boolean flag to refund to the courier.
     */
    function refundPayment(
        address _storeAddress,
        string memory _orderId,
        bool toCustomer,
        bool toStore,
        bool toCourier
    ) external onlyStore {
        IFooDriverStore.Order memory refundOrder = IFooDriverStore(_storeAddress).getOrderById(_orderId);

        if (refundOrder.customerAddress == address(0)) {
            revert OrderDoesNotExist();
        }
        if (refundOrder.status == IFooDriverStore.OrderStatus.Refunded) {
            revert OrderAlreadyRefunded();
        }
        if (refundOrder.status == IFooDriverStore.OrderStatus.Completed) {
            revert OrderAlreadyCompleted();
        }

        uint256 storeRefundAmount = 0;
        uint256 customerRefundAmount = 0;
        uint256 courierRefundAmount = 0;

        if (toCustomer) {
            customerRefundAmount = refundOrder.deliveryAmount + refundOrder.amount + refundOrder.weightGoodsDepositAmount + (refundOrder.amount * refundOrder.customerGuaranteeDepositPercent / 100);
        }

        if (toStore) {
            storeRefundAmount = refundOrder.amount * (refundOrder.storeGuaranteeDepositPercent + refundOrder.appCommissionPercent) / 100;
        }

        if (toCourier && refundOrder.courierAddress != address(0)) {
            courierRefundAmount = refundOrder.amount + refundOrder.amount * refundOrder.courierGuaranteeDepositPercent / 100;
        }

        if (toCustomer && customerRefundAmount > 0) {
            IERC20(token).transfer(refundOrder.customerAddress, customerRefundAmount);
        }

        if (toStore && storeRefundAmount > 0) {
            IERC20(token).transfer(refundOrder.storeAddress, storeRefundAmount);
        }

        if (toCourier && courierRefundAmount > 0) {
            IERC20(token).transfer(refundOrder.courierAddress, courierRefundAmount);
        }
    }
    /**
       * @notice Withdraws a specified ERC20 token from the contract to a designated address.
     * @dev Accessible only by an account with the `REGISTRY_ROLE`.
     * @param _tokenAddress Address of the ERC20 token to withdraw.
     * @param _amount Amount of tokens to withdraw.
     * @param _to Recipient address of the withdrawn tokens.
     */
    function withdrawERC20Token(address _tokenAddress, uint256 _amount, address _to) public onlyRegistry {
        IERC20 tokenContract = IERC20(_tokenAddress);
        tokenContract.transfer(_to, _amount);
    }
    /**
       * @dev Internal function to authorize contract upgrades, accessible only by the upgrader role.
     * @param newImplementation Address of the new contract implementation to upgrade to.
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyUpgrader
    override
    {}
}
