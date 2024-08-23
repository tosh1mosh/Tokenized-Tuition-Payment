// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Custom Ownable Contract
abstract contract CustomOwnable {
    address private _owner;

    event Ownershiptransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit Ownershiptransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "CustomOwnable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "CustomOwnable: new owner is the zero address");
        emit Ownershiptransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Token Contract
contract TuitionToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("TuitionToken", "TTK") {
        _mint(msg.sender, initialSupply);
    }
}

// Payment Contract
contract TuitionPayment is CustomOwnable, ReentrancyGuard {
    IERC20 public token;
    uint256 public totalTuition;
    uint256 public installmentAmount;
    uint256 public numberOfInstallments;
    uint256 public paymentRateLimit;

    mapping(address => uint256) public installmentsPaid;
    mapping(address => uint256) public studentTotalPayments;

    event PaymentMade(address indexed student, uint256 amount);
    event FundsWithdrawn(address indexed admin, uint256 amount);

    constructor(
        address _token,
        uint256 _totalTuition,
        uint256 _installmentAmount,
        uint256 _numberOfInstallments,
        uint256 _paymentRateLimit
    ) {
        require(_token != address(0), "Invalid token address");
        require(_totalTuition > 0, "Total tuition must be greater than 0");
        require(_installmentAmount > 0, "Installment amount must be greater than 0");
        require(_numberOfInstallments > 0, "Number of installments must be greater than 0");
        require(_paymentRateLimit > 0, "Payment rate limit must be greater than 0");
        
        token = IERC20(_token);
        totalTuition = _totalTuition;
        installmentAmount = _installmentAmount;
        numberOfInstallments = _numberOfInstallments;
        paymentRateLimit = _paymentRateLimit;
    }

    function payInstallment(uint256 amount) external nonReentrant {
        require(amount == installmentAmount, "Incorrect installment amount");
        require(installmentsPaid[msg.sender] < numberOfInstallments, "All installments already paid");

        uint256 installmentsRemaining = numberOfInstallments - installmentsPaid[msg.sender];
        require(installmentsRemaining > 0, "No installments left to pay");
        require(studentTotalPayments[msg.sender] + amount <= paymentRateLimit, "Payment exceeds rate limit");

        token.transferFrom(msg.sender, address(this), amount);
        installmentsPaid[msg.sender]++;
        studentTotalPayments[msg.sender] += amount;

        emit PaymentMade(msg.sender, amount);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        token.transfer(owner(), balance);
        emit FundsWithdrawn(owner(), balance);
    }

    function getInstallmentsPaid() external view returns (uint256) {
        return installmentsPaid[msg.sender];
    }

    function getStudentTotalPayments(address student) external view returns (uint256) {
        return studentTotalPayments[student];
    }
}

// Counter Contract
contract Counter {
    uint private counterVariable = 0;

    function increment() public {
        counterVariable++;
    }

    function retrieve() public view returns (uint) {
        return counterVariable;
    }
}
