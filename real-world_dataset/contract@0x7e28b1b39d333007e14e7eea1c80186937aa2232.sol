pragma solidity ^0.4.13;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
}


contract RBInformationStore is Ownable {
    address public profitContainerAddress;
    address public companyWalletAddress;
    uint public etherRatioForOwner;
    address public multiSigAddress;
    address public accountAddressForSponsee;

    modifier onlyMultiSig() {
        require(multiSigAddress == msg.sender);
        _;
    }

    function RBInformationStore
    (
        address _profitContainerAddress,
        address _companyWalletAddress,
        uint _etherRatioForOwner,
        address _multiSigAddress,
        address _accountAddressForSponsee
    ) {
        profitContainerAddress = _profitContainerAddress;
        companyWalletAddress = _companyWalletAddress;
        etherRatioForOwner = _etherRatioForOwner;
        multiSigAddress = _multiSigAddress;
        accountAddressForSponsee = _accountAddressForSponsee;
    }

    function changeProfitContainerAddress(address _address) onlyMultiSig {
        profitContainerAddress = _address;
    }

    function changeCompanyWalletAddress(address _address) onlyMultiSig {
        companyWalletAddress = _address;
    }

    function changeEtherRatioForOwner(uint _value) onlyMultiSig {
        etherRatioForOwner = _value;
    }

    function changeMultiSigAddress(address _address) onlyMultiSig {
        multiSigAddress = _address;
    }

    function changeOwner(address _address) onlyMultiSig {
        owner = _address;
    }

    function changeAccountAddressForSponsee(address _address) onlyMultiSig {
        accountAddressForSponsee = _address;
    }
}
