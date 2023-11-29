// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../proof-of-identity/interfaces/IProofOfIdentity.sol";

/**
 * @title Social Media Authenticator
 * @notice A Social Media Authenticator that utilizes Haven1 Proof of Identity interface for Unique Identity  Issuance
 * @dev A Social Media Authenticator that utilizes Haven1 Proof of Identity interface for Unique Identity  Issuance
 */

contract SocialMediaAuthentication {

    //STATE VARIABLES

    /**
     * @dev Account Type: Personal 
     * Only Accounts Marked with Personal will be verified
    **/

    uint256 private constant _PERSONAL = 1;

    /**
     * @dev Account Type: Organization 
     * Only Accounts Marked with Organization will be verified
    **/

    uint256 private constant _ORGANIZATION = 2;

    /**
     * @dev Account Type: Any 
     * Accounts Marked with Any will be verified
    **/

    uint256 private constant _ANY = 3;

    //Type of Account whether Personal, Organization or Any
    uint256 private _accountType;

    //User Address
    address private _userAddress;

    // Counter to keep track of the last assigned user ID
    uint256 private nextUserID;

    // Variable to store Account eligibility
    bool private _isEligible;

    // The Proof if Idetity Contract
    IProofOfIdentity public _proofOfIdentity;

    // The NFT prize.
    IERC721 private _nft;

    // The ID of the NFT prize.
    uint256 private _nftId;

    //User Struct
    struct User {
        address walletAddress;
        uint256 userID;
        uint256 _accountType;
        string countryCode;
    }

    //Mapping Users to an Array
    mapping (uint256 => User) private users;


    
    // EVENTS

    //Event to emit once user is authenticated
    event UserAuthenticated(address indexed user);

    //Event to Emit if user autnentication was not successful
    event UserNotAuthenticated(address indexed user);

    //Event to emit if user supplies an Invalid Account Type
    event InvalidAccountType(uint256 typeProvided);

    // Event to emit when a new user ID is generated
    event UserIDGenerated(address indexed user, uint256 userID);

    // Event to EMit once POI address is updates
    event POIAddressUpdated(address poi);


    //ERRORS

    // Error to throw when the zero address has been supplied and it is not allowed.
    error SocialMediaPOI__ZeroAddress();

    // Error to throw if user has no Identity NFT
    error SocailMediaPOI__NoIdentityNFT();

    // Error to throw when an Attribute is Insufficient 
    error SocailMediaPOI__InvalidUserType(uint256 userType);

    modifier onlyVerifiedUser() {
        // ensure the user address is not zero
        if (_userAddress == address(0)) revert SocialMediaPOI__ZeroAddress();


        // check the verification status
        bool isVerified = true;
        emit UserAuthenticated(_userAddress);
        require(isVerified, "SocialMediaAuthenticator: User not verified");

        _;
    }

    
    //FUNCTIONS

    function _setPOIAddress(address poi) private {
        if (poi == address(0)) revert SocialMediaPOI__ZeroAddress();
        _proofOfIdentity = IProofOfIdentity(poi);
        emit POIAddressUpdated(poi);
    }

    

    function accountEligible(address account) external view returns (bool) {
        if (!_hasID(account)) return false;
        if (!_checkUserType(account)) return false;
        return true;
    }


    function authenticateUser(
        address userAddress_,
        string calldata _countryCode,
        bool _proofOfLiveliness,
        uint256 _userType,
        uint256[4] calldata _expiries,
        string calldata _uri
    ) external {

        require(userAddress_ != address (0), "Invalid Wallet Address");
            

        // Issue Proof of Identity NFT
        _proofOfIdentity.issueIdentity(
            msg.sender,
            _proofOfLiveliness,
            _countryCode,
            _proofOfLiveliness,
            _userType,
            _expiries,
            _uri
        );
    }
    

    //Function to Check if account has the NFT ID
    function _hasID(address account) private view returns (bool) {
        return _proofOfIdentity.balanceOf(account) > 0;
    }

    //FUnction to check the type of Account meets the criteria
    function _hasType(uint256 userType) private view returns (bool) {
        return (_accountType & userType) > 0;
    }

    //Funtion to get that Return the Address of the NFT and the ID
    function getNFT() external view returns (address, uint256) {
        return (address(_nft), _nftId);
    }


    //Function to check if an Account is suspended 
    function _isSuspended(address account) private view returns (bool) {
        return _proofOfIdentity.isSuspended(account);
    }

    // Function to Check the validity of a User Account Type
    function _checkUserType(address account) private view returns (bool) {
        (uint256 user, ,) = _proofOfIdentity.getUserType(account);
        if (!_hasType(user)) return false;
        return true;
    }


    //CONSTRUCTOR
    constructor(
        address proofOfIdentity_,
        uint256 accountType_,
        address nft_,
        uint256 nftId_
    ) {
        if (accountType_ == 0 || accountType_ > _ANY) {
            revert SocailMediaPOI__InvalidUserType(accountType_);
        }
        _setPOIAddress(proofOfIdentity_);

        _accountType = accountType_;

        _nft = IERC721(nft_);
        _nftId = nftId_;
    }
    
}
