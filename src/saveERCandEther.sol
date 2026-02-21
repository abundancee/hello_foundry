// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract saveERCandEther {
    // Mapping to track Ether balances: user address => ether balance
    mapping(address => uint256) public etherBalances;
    
    // Mapping to track ERC20 balances: user address => token address => token balance
    mapping(address => mapping(address => uint256)) public tokenBalances;

    // Events
    event EtherDeposited(address indexed user, uint256 amount);
    event EtherWithdrawn(address indexed user, uint256 amount);
    event TokenDeposited(address indexed user, address indexed token, uint256 amount);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);

   
    function depositEther() external payable {
        require(msg.value > 0, "Cannot deposit zero Ether");
        
        etherBalances[msg.sender] += msg.value;
        
        emit EtherDeposited(msg.sender, msg.value);
    }

   
    function withdrawEther(uint256 _amount) external {
        require(msg.sender != address(0), "Invalid address");
        require(_amount > 0, "Cannot withdraw zero amount");
        require(etherBalances[msg.sender] >= _amount, "Insufficient Ether balance");
        
        etherBalances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Ether transfer failed");
        
        emit EtherWithdrawn(msg.sender, _amount);
    }

   
    function depositToken(address _token, uint256 _amount) external {
        require(_token != address(0), "Invalid token address");
        require(_amount > 0, "Cannot deposit zero tokens");
        
        // Transfer tokens from user to this contract
        bool success = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");
        
        tokenBalances[msg.sender][_token] += _amount;
        
        emit TokenDeposited(msg.sender, _token, _amount);
    }

    
    function withdrawToken(address _token, uint256 _amount) external {
        require(_token != address(0), "Invalid token address");
        require(msg.sender != address(0), "Invalid user address");
        require(_amount > 0, "Cannot withdraw zero tokens");
        require(tokenBalances[msg.sender][_token] >= _amount, "Insufficient token balance");
        
        tokenBalances[msg.sender][_token] -= _amount;
        
        bool success = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Token transfer failed");
        
        emit TokenWithdrawn(msg.sender, _token, _amount);
    }

    function getEtherBalance() external view returns (uint256) {
        return etherBalances[msg.sender];
    }

    function getTokenBalance(address _token) external view returns (uint256) {
        return tokenBalances[msg.sender][_token];
    }

  
    function getUserEtherBalance(address _user) external view returns (uint256) {
        return etherBalances[_user];
    }

   
    function getUserTokenBalance(address _user, address _token) external view returns (uint256) {
        return tokenBalances[_user][_token];
    }

   
    function getContractEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // Receive function to accept Ether
    receive() external payable {
        etherBalances[msg.sender] += msg.value;
        emit EtherDeposited(msg.sender, msg.value);
    }

    // Fallback function
    fallback() external payable {}
}
