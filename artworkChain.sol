// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract ArtApp{
    address payable transactionWallet;
    uint constant public BUYER = 1;
    uint constant public SELLER = 2;
    uint constant public VERIFIER = 3;
    struct Certification {
        string imgHash; 
        address payable verifier;
        address payable seller;
        string certifyStatement;
    }

    struct Artwork{
        string image;
        string imgHashId;
        address payable sellerWallet;
        address payable ownership;
        uint256 price;
        bool isAuctioned;
        Certification certificate;
        uint256 highestBid;
        address payable highestBidder;
    }
    struct PendingArt{
        string image;
        string imgHashId;
        address payable sellerWallet;
        address payable ownership;
        uint256 price;
        bool isActioned;
    }
    
    struct User{
        string name;
        address payable wallet;
        uint userType;
        string [] ownedArts;
        string certificateSign;
    }

    struct Buyer{
        string name;
        address payable wallet;
        uint[] OwnedArts;
    }
    
    struct Seller{
        string name;
        address payable wallet;
        uint[] OwnedArts;
    }
    
    struct Verifier{
        string name;
        address payable wallet;
        string signature;
    }
    
    mapping(address => bool) public suppliers;
    mapping(address => bool) public buyers;
    mapping(address => bool) public verifiers;
    mapping(address => User) public registeredUsers;
    mapping(string => Artwork) public artCollection;
    string[] private _artHashIds;
    // Artwork[] public artworks;
    mapping(string => PendingArt) yetToVerify;
    string[] private _pendingIds;
    // PendingArt[] public enlistedArt;
    // Certification[] public certificates;
    mapping(string => Certification) allCertificate;
    
    
    modifier onlySupplier() {
        require(suppliers[msg.sender], "Only suppliers can call this function.");
        _;
    }

    modifier onlyBuyer() {
        require(buyers[msg.sender], "Only buyers can call this function.");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Only verifiers can call this function.");
        _;
    }
    
    
    function registerUser(string memory _name, uint _userType, string memory _signature) public{
        if (_userType == BUYER){
            buyers[msg.sender] = true;
            registeredUsers[msg.sender] = User({
                                name: _name,
                                wallet: payable(msg.sender),
                                userType: BUYER,
                                ownedArts: new string[](0),
                                certificateSign: ""
                    });
        }
        else if (_userType == SELLER){
            suppliers[msg.sender] = true;
            registeredUsers[msg.sender] = User({
                                name: _name,
                                wallet: payable(msg.sender),
                                userType: SELLER,
                                ownedArts: new string[](0),
                                certificateSign: ""
                    });
        }
        else{
            verifiers[msg.sender] = true;
            registeredUsers[msg.sender] = User({
                                name: _name,
                                wallet: payable(msg.sender),
                                userType: VERIFIER,
                                ownedArts: new string[](0),
                                certificateSign: _signature
                    });
        }
    }


    constructor() {
        // suppliers[msg.sender] = true;
        // transactionWallet = payable(msg.sender);
    }
    
    function enlistArtwork(
        string memory _image,string memory _hash, uint256 _price, bool _isAuction
    ) external onlySupplier {
        yetToVerify[_hash] = PendingArt(
        {
            image: _image,
            imgHashId: _hash,
            sellerWallet: payable(msg.sender),
            ownership: payable(msg.sender),
            price: _price,
            isActioned: _isAuction
        });
        _pendingIds.push(_hash);
    }
    
    // function issueCertificat(uint128 _artId) public returns(storage Certification){
    //     require(enlistedArt.length != 0, "Empty");
    //     PendingArt storage pending = enlistedArt[_artId];
    //     return pending
    // }

    function verification(PendingArt memory _pending) public view onlyVerifier returns(bool){
        for (uint i=0; i<_artHashIds.length; i++){
            if (compareStrings(_artHashIds[i], _pending.imgHashId)) { return false; }
        }
        return true;
    }
    
    function certifyArt(address payable _seller, string memory _imgHash) public{
        allCertificate[_imgHash] = Certification(_imgHash, payable(msg.sender), _seller, 
                            registeredUsers[msg.sender].certificateSign); 
    }
    
    function addArtwork(string memory _hash) external onlyVerifier {
        require(_pendingIds.length != 0, "Empty");
        Artwork memory arts;
        // PendingArt memory pending = enlistedArt[_artId-1];
        PendingArt memory pending = yetToVerify[_hash];
        if (verification(pending)==true){
            certifyArt(pending.sellerWallet, pending.imgHashId);
            arts = Artwork(pending.image, _hash, pending.sellerWallet, pending.sellerWallet, pending.price,
                            pending.isActioned, allCertificate[_hash], 0, payable(0));
            registeredUsers[pending.sellerWallet].ownedArts.push(_hash);
            artCollection[_hash] = arts;
            for (uint128 idx=0; idx<_pendingIds.length-1; idx++){
                if (compareStrings(_pendingIds[idx], _hash)){
                    _pendingIds[idx] = _pendingIds[idx+1];
                    _pendingIds[idx+1] = _hash;
                }
            }
            delete yetToVerify[_hash];
            _pendingIds.pop();
            registeredUsers[pending.sellerWallet].ownedArts.push(_hash);
        }
        //emit ArtworkAdded(artworkId, _description, _price);
    }
    
    function getArtWorkInfo(string memory _hash) public view returns(string memory){
        // string memory info = artworks[artId].image + " price: " + string(artworks[artId].price);
        return artCollection[_hash].image;
    }
    
    function availableUncertifiedArts() public view onlyVerifier returns(uint256){
        return _pendingIds.length;
    }

    
    function getSellerWallet(string memory _hash) public view onlyBuyer returns(address payable){
        return artCollection[_hash].sellerWallet;
    }
    
    function transferOwnership(address payable _wallet, string memory _hash) public onlySupplier{
        registeredUsers[_wallet].ownedArts.push(_hash);
        artCollection[_hash].ownership = _wallet;
        for(uint i=0; i<registeredUsers[msg.sender].ownedArts.length-1; i++){
            if (compareStrings(registeredUsers[msg.sender].ownedArts[i], _hash)){
                registeredUsers[msg.sender].ownedArts[i] = registeredUsers[msg.sender].ownedArts[i+1];
                registeredUsers[msg.sender].ownedArts[i+1] = _hash;
            }
        }
        registeredUsers[msg.sender].ownedArts.pop();
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }


    function validateCertificate(string memory _hash) public view onlyBuyer returns(bool){
        string memory verifier_signature = registeredUsers[allCertificate[_hash].verifier].certificateSign;
        string memory certifier = allCertificate[_hash].certifyStatement;
        if (compareStrings(certifier, verifier_signature)) return true;
        else return false;
    }
    
    function checkMyState() public view returns(string memory) {
        if (buyers[msg.sender]) return "buyer";
        if (suppliers[msg.sender]) return "seller";
        if (verifiers[msg.sender]) return "verifier";
        return "";
    }

}