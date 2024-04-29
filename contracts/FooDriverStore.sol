// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFooDriverStore} from "./interfaces/IFooDriverStore.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFooDriverBank} from "./interfaces/IFooDriverBank.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
/**
 * @title FooDriverStore
 * @dev Contract for managing individual store orders within the FooDriver platform.
 *      This contract handles order creation, modification, and financial interactions via the FooDriverBank.
 */
contract FooDriverStore is IFooDriverStore {
    string public storeId;
    address public immutable i_registry;
    address public immutable i_bank;
    address public immutable i_token;
    mapping(string => Order) public orders;
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");

    /**
     * @notice Initializes a new store with necessary addresses and permissions.
     * @param _storeId Unique identifier for the store.
     * @param _registry Address of the registry contract managing roles.
     * @param _bank Address of the FooDriverBank contract handling financial transactions.
     * @param _token Address of the ERC20 token used for transactions.
     */
    constructor(
        string memory _storeId,
        address _registry,
        address _bank,
        address _token
    )  {
        storeId = _storeId;
        i_registry = _registry;
        i_bank = _bank;
        i_token = _token;
        IERC20(_token).approve(_bank, 2 ** 256 - 1);
    }

    modifier onlyRegistry() {
        if (!IAccessControl(i_registry).hasRole(REGISTRY_ROLE, msg.sender)) {
            revert NotRegistry();
        }
        _;
    }
    /**
        * @notice Creates a new order with specific financial commitments.
     * @param _orderId Unique identifier for the order.
     * @param _customerAddress Address of the customer involved in the order.
     * @param _amount Total amount of the transaction.
     * @param _deliveryAmount Delivery fee associated with the order.
     * @param _storeGuaranteeDepositPercent Percentage of the total amount locked as a store deposit.
     * @param _customerGuaranteeDepositPercent Percentage of the total amount locked as a customer deposit.
     * @param _courierGuaranteeDepositPercent Percentage of the total amount locked as a courier deposit.
     * @param _appCommissionPercent Percentage commission taken by the platform.
     * @param _weightGoodsDepositAmount Additional deposit based on the weight of the goods.
     * @return orderId The ID of the newly created order.
     */
    function createOrder(
        string memory _orderId,
        address _customerAddress,
        uint256 _amount,
        uint256 _deliveryAmount,
        uint256 _storeGuaranteeDepositPercent,
        uint256 _customerGuaranteeDepositPercent,
        uint256 _courierGuaranteeDepositPercent,
        uint256 _appCommissionPercent,
        uint256 _weightGoodsDepositAmount
    ) external onlyRegistry returns (string memory orderId) {
        if (_customerAddress == address(0)) {
            revert InvalidCustomerAddress();
        }
        if (orders[_orderId].customerAddress != address(0)) {
            revert OrderAlreadyExists();
        }
        uint256 customerLockAmount = _amount * _customerGuaranteeDepositPercent / 100 + _amount + _deliveryAmount + _weightGoodsDepositAmount;
        IFooDriverBank(i_bank).lockCustomerPayment(customerLockAmount, _customerAddress);
        Order memory newOrder = Order({
            id: _orderId,
            customerAddress: _customerAddress,
            storeAddress: address(this),
            courierAddress: address(0),
            amount: _amount,
            deliveryAmount : _deliveryAmount,
            status: OrderStatus.Pending,
            storeGuaranteeDepositPercent: _storeGuaranteeDepositPercent,
            customerGuaranteeDepositPercent: _customerGuaranteeDepositPercent,
            courierGuaranteeDepositPercent: _courierGuaranteeDepositPercent,
            appCommissionPercent: _appCommissionPercent,
            weightGoodsDepositAmount: _weightGoodsDepositAmount
        });

        orders[_orderId] = newOrder;
        return _orderId;
    }
    /**
        * @notice Confirms an order, locking additional store payments.
     * @dev Changes the order status to confirmed and locks the store's financial commitment.
     * @param _orderId Unique identifier of the order to confirm.
     * @return orderId The ID of the confirmed order.
     */
    function confirmOrder(
        string memory _orderId
    ) external onlyRegistry returns (string memory orderId) {
        if (orders[_orderId].customerAddress == address(0)) {
            revert OrderDoesNotExist();
        }
        if (orders[_orderId].status != OrderStatus.Pending) {
            revert OrderNotPending();
        }
        uint256 amount = orders[_orderId].amount;
        uint256 storeGuaranteeDepositPercent = orders[_orderId].storeGuaranteeDepositPercent;
        uint256 appCommissionPercent = orders[_orderId].appCommissionPercent;
        uint256 storeLockAmount = amount * storeGuaranteeDepositPercent / 100 + amount * appCommissionPercent / 100;
        IFooDriverBank(i_bank).lockStorePayment(storeLockAmount, address(this));
        orders[_orderId].status = OrderStatus.Confirmed;
        return _orderId;
    }

    /**
    * @notice Assigns a courier to an order and locks their payment.
     * @param _orderId The ID of the order.
     * @param _courierAddress The address of the courier.
     */
    function addCourierToOrder(string memory _orderId, address _courierAddress) external onlyRegistry {
        if (orders[_orderId].status != OrderStatus.Confirmed) {
            revert OrderNotConfirmed();
        }
        IFooDriverBank(i_bank).lockCourierPayment(_orderId, address(this), _courierAddress);
        orders[_orderId].courierAddress = _courierAddress;
        orders[_orderId].status = OrderStatus.InDelivery;
    }
    /**
   * @notice Changes the assigned courier of an order.
     * @param _orderId The ID of the order.
     * @param _courierAddress The new courier's address.
     */
    function changeCourierInOrder(string memory _orderId, address _courierAddress) external onlyRegistry {
        if (orders[_orderId].status != OrderStatus.InDelivery) {
            revert OrderNotInDelivery();
        }
        IFooDriverBank(i_bank).unlockCourierPayment(_orderId, address(this));
        IFooDriverBank(i_bank).lockCourierPayment(_orderId, address(this), _courierAddress);
        orders[_orderId].courierAddress = _courierAddress;
    }


    /**
     * @notice Retrieves the details of a specific order by its ID.
     * @param _orderId The ID of the order to retrieve.
     * @return Order The details of the specified order.
     */
    function getOrderById(string memory _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }

    /**
    * @notice Finalizes an order, releasing all associated payments.
     * @param _orderId The ID of the order to finalize.
     * @param _weightGoodsReturn Amount to adjust for returned goods.
     */
    function releaseOrder(string memory _orderId , uint256 _weightGoodsReturn) external onlyRegistry {
        IFooDriverBank(i_bank).releasePayment(address(this), _orderId, _weightGoodsReturn);
        orders[_orderId].status = OrderStatus.Completed;
    }
    /**
       * @notice Refunds all or some participants in an order.
     * @param _orderId The ID of the order.
     * @param toCustomer Boolean indicating if the customer should be refunded.
     * @param toStore Boolean indicating if the store should be refunded.
     * @param toCourier Boolean indicating if the courier should be refunded.
     */
    function refundOrder(string memory _orderId, bool toCustomer,
        bool toStore,
        bool toCourier) external onlyRegistry {
        IFooDriverBank(i_bank).refundPayment(address(this), _orderId, toCustomer,
            toStore,
            toCourier);
        orders[_orderId].status = OrderStatus.Refunded;
    }
    /**
      * @notice Allows the registry to withdraw ERC20 tokens to a specified address.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _to The recipient of the withdrawn tokens.
     */
    function withdrawERC20Token(address _tokenAddress, uint256 _amount, address _to) public onlyRegistry {
        IERC20 tokenContract = IERC20(_tokenAddress);
        tokenContract.transfer(_to, _amount);
    }
}
