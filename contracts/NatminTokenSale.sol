pragma solidity ^0.4.22;

import "./NatminToken.sol";

contract NatminTokenSale is Ownable {
	using SafeMath for uint256;

	NatminToken internal 	tokenContract;
	uint256 	constant 	tokenPrice = 50000000000000; //token price in wei = 0.00005 ether
	uint256 	public 		tokensSold; //amount of tokens sold
	uint256 	public 		amountRaised; //in wei
	uint256 	internal  	minBuyValue = 10000000000000000; //in wei = 0.01 ether
	address 	internal 	wallet;
	uint256 	internal 	startTime;
	uint256 	internal 	endTime;

	mapping(address => bool) whitelist;

	constructor(NatminToken _tokenContract, address _wallet) public {
		require(_wallet != 0x0);
		tokenContract = _tokenContract;
		wallet = _wallet;
		startTime = now;
		endTime = startTime + 31 days;
	}

	// Default function that triggers the buytokens() when ether is sent to the contract.
	function () public payable {
		buyTokens(msg.sender, msg.value);
	}

	// Buying tokens when ether is sent to contract. 
	function buyTokens(address _buyer, uint256 _value) internal {
		require(tokenSaleHasStarted());
		require(!tokenSaleHasEnded());
		require(validPurchase());

		uint256 _tokenAmount = calculateTokensToBuy();

		tokenContract.transfer(_buyer, _tokenAmount);		
		amountRaised = amountRaised.add(_value);
		tokensSold = tokensSold.add(_tokenAmount);

		forwardFundsToWallet(_value);		
	}

	// Sending funds to external wallet as they arrive.
	function forwardFundsToWallet(uint256 _value) internal {
		wallet.transfer(_value);					
	}

	// Validate if token sale has started.
	function tokenSaleHasStarted() public view returns (bool) {
		return now > startTime; 
	}

	// Validate if token sale has ended.
	function tokenSaleHasEnded() public view returns (bool) {
		return now > endTime;
	}

	// Validate if the amount sent is more than the minimum buy value.
	// Validate if contract still has allocated tokens available.
	function validPurchase() internal view returns (bool) {
		bool _validBuyValue = msg.value >= minBuyValue;		
		bool _validAmount = tokenContract.balanceOf(this) >= calculateTokensToBuy();
		return _validBuyValue && _validAmount;		
	}

	// Calculate the amount of tokens purchased with the eth amount sent.
	function calculateTokensToBuy() internal view returns (uint256 _amount) {
		_amount = (msg.value / tokenPrice) * (10 ** 18);
		uint256 _bonusAmount = bonusTokensAmount(_amount);
		return _amount = _amount.add(_bonusAmount);
	}

	// Calculate the bonus amount 
	function bonusTokensAmount(uint256 _amount) internal view returns (uint256 _bonusAmount) {

		// Calculate rate for first 3 days = 35%
		if ((now >= startTime) && (now <= startTime + 3 days)) {
			_bonusAmount = _amount.mul(35).div(100);
			return _bonusAmount;
		}

		// Calculate rate for first week = 25%
		if ((now > startTime + 3 days) && (now <= startTime + 10 days)) {
			_bonusAmount = _amount.mul(25).div(100);
			return _bonusAmount;
		}

		// Calculate rate for second week = 20%
		if ((now > startTime + 10 days) && (now <= startTime + 17 days)) {
			_bonusAmount = _amount.mul(20).div(100);
			return _bonusAmount;
		}

		// Calculate rate for third week = 15%
		if ((now > startTime + 17 days) && (now <= startTime + 24 days)) {
			_bonusAmount = _amount.mul(15).div(100);
			return _bonusAmount;
		}

		// Calculate rate for fourth week = 10%
		if ((now > startTime + 24 days) && (now < endTime)) {
			_bonusAmount = _amount.mul(10).div(100);
			return _bonusAmount;
		}

		return 0;
	}


	// Transfers the balance of the token  contract back to the contract owner
	function endTokenSale() public ownerOnly {
        require(tokenContract.transfer(contractOwner, tokenContract.balanceOf(this)));
        endTime = now;

        selfdestruct(contractOwner);
    }

    // Start tokensale manually
    function startTokenSale() public ownerOnly {
    	startTime = now;
		endTime = startTime + 31 days;
    }

    // Get the current balance of the contract
    function getContractBalance() public ownerOnly view returns (uint256) {
    	return tokenContract.balanceOf(this);
    }

    // Validate if sender is on the whitelist
    function validateWhitelist(address _user) public view returns (bool) {
		return whitelist[_user];
	}

	// Add a specified user to the whitelist
    function addWhitelist(address _user) public ownerOnly {
    	whitelist[_user] = true;
    }
}