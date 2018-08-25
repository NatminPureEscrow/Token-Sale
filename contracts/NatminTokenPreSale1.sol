pragma solidity ^0.4.22;
 import "./NatminToken.sol";
 contract NatminTokenPreSale is Ownable {
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
		endTime = startTime + 7 days;
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
	// Validate if the user is on the whitelist.
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
	function bonusTokensAmount(uint256 _amount) internal pure returns (uint256 _bonusAmount) {
 		// Calculate rate 45% for pre-sale period
		_bonusAmount = _amount.mul(45).div(100);
		return _bonusAmount;
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
    }
     // Get the current balance of the contract
    function getContractBalance() public ownerOnly view returns (uint256) {
    	return tokenContract.balanceOf(this);
    }
 }