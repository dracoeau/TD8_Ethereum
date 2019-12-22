pragma solidity >=0.4.22 <0.6.0;

contract ticketingSystem {

  // Structure artiste, id artiste depuis la variable globale et mapping entre l'id comme cle et la structure artiste comme valeur
  uint256 public nextArtistNumber;
  mapping(uint256 => Artist) public artistsRegister;

  struct Artist {
    address payable owner;
	bytes32 name;
	uint256 artistCategory;
	uint256 totalTicketSold;
  }


  // Structure venue, idvenue et mapping
  uint256 public nextVenueNumber;
  mapping(uint256 => Venue) public venuesRegister;
  
  struct Venue {
	address payable owner;
	bytes32 name;
	uint256 capacity;
	uint256 standardComission;
  }

  // Structure concert, idconcert et mapping
  uint256 public nextConcertNumber;
  mapping(uint256 => Concert) public concertsRegister;
  
  struct Concert {
	uint256 artistId;
	uint256 venueId;
	uint256 concertDate;
	uint256 ticketPrice;
	uint256 totalSoldTicket;
	uint256 totalMoneyCollected;
	bool validatedByArtist;
	bool validatedByVenue;
  }

  // Structure ticket, ticketid et mapping
  uint256 public nextTicketNumber;
  mapping(uint256 => Ticket) public ticketsRegister;
  
  struct Ticket {
    address payable owner;
    bool isAvailable;
	uint256 concertId;
    uint256 amountPaid;
    bool isAvailableForSale;
	uint256 salePrice;
  }

  // Constructeur, initialisation des variable globales a 1 lors de la creation du contrat
  constructor() public {
	nextArtistNumber = 1;
	nextVenueNumber = 1;
	nextConcertNumber = 1;
	nextTicketNumber = 1;
  }

  function createArtist(bytes32 artistName, uint256 artistCategory) public {
	Artist memory newArtist = Artist(msg.sender,artistName,artistCategory,0);
	artistsRegister[nextArtistNumber] = newArtist;
	nextArtistNumber += 1;
  }

  function modifyArtist(uint256 artistId, bytes32 nameArtist, uint256 artistCategory, address payable newOwner) public 
  {
	// Pour passer le try catch du test, 
	// il faut verifier que la personne qui veut modifier les informations de l'artiste est bien l'artiste en personne
	require(artistsRegister[artistId].owner == msg.sender);
    artistsRegister[artistId].owner = newOwner;
    artistsRegister[artistId].name = nameArtist;
    artistsRegister[artistId].artistCategory = artistCategory;
  }

  function createVenue(bytes32 _name, uint256 _capacity, uint256 _standardComission) public {
	Venue memory newVenue = Venue(msg.sender, _name, _capacity, _standardComission);
	venuesRegister[nextVenueNumber] = newVenue;
	nextVenueNumber += 1;
  }

  function modifyVenue(uint256 venueId, bytes32 venueName, uint256 venueCapacity, uint256 venueComission, address payable owner) public {
    // Seul la personne qui a creer la venue peut la modifier, d'ou le require
	require(venuesRegister[venueId].owner == msg.sender);
	venuesRegister[venueId].name = venueName;
	venuesRegister[venueId].capacity = venueCapacity;
	venuesRegister[venueId].standardComission = venueComission;
	venuesRegister[venueId].owner = owner;
  }

  function createConcert(uint256 _artistId, uint256 _venueId, uint256 _concertDate, uint256 _ticketPrice) public {
	Concert memory newConcert = Concert(_artistId,_venueId,_concertDate,_ticketPrice,0,0,false,false);
	concertsRegister[nextConcertNumber] = newConcert;
	validateConcert(nextConcertNumber);
	nextConcertNumber += 1;
  }
  
  function validateConcert(uint256 _concertId) public {
	// Tester si l'artiste du concert en question a bien émis le création de ce concert
	uint256 idArtist = concertsRegister[_concertId].artistId;
	uint256 idVenue = concertsRegister[_concertId].venueId;
	// On regarde si l'addresse de l'artiste est equivalente à l'addresse qui a emis la creation du concert
	// Pareil avec la venue
	if (artistsRegister[idArtist].owner == msg.sender) concertsRegister[_concertId].validatedByArtist = true;
	if (venuesRegister[idVenue].owner == msg.sender) concertsRegister[_concertId].validatedByVenue = true;
  }

    function emitTicket(uint256 _concertId, address payable _ticketOwner) public {
	  // Only artists can emit tickets
	  uint256 artistIdConcert = concertsRegister[_concertId].artistId;
	  address payable artistOwnerAddress = artistsRegister[artistIdConcert].owner;
	  require(artistOwnerAddress == msg.sender);
	  
	  concertsRegister[_concertId].totalSoldTicket += 1;
	  Ticket memory newTicket = Ticket(_ticketOwner,true,_concertId,0,false,0);
	  ticketsRegister[nextTicketNumber] = newTicket;
	  nextTicketNumber += 1;
	}
    
	function useTicket(uint256 _ticketId) public {
	  // Verifier que la personne qui veut utiliser le ticket est bien le proprietaire du ticket
	  require(ticketsRegister[_ticketId].owner == msg.sender);
	  
	  // Verifier que ce ticket vient bien d'un concert qui a ete valide par l'artiste et la venue
      require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByArtist);
      require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue);
	  
	  // Et finalement il faut verifier si le ticket correspond bien aux dates du concert
      require(concertsRegister[ticketsRegister[_ticketId].concertId].concertDate < now + 60*60*24);
	  
	  // We used the ticket so we delete it now in the mapping
      delete ticketsRegister[_ticketId];
    }
	
	function buyTicket(uint256 _concertId) public payable {
	  // On fait monter le nombre de tickets vendus et increment de l'argent gagne pour le concert donnee
	  concertsRegister[_concertId].totalSoldTicket +=1;
      concertsRegister[_concertId].totalMoneyCollected += msg.value;
	  
	  // On met le montant du ticket
	  ticketsRegister[nextTicketNumber].concertId = _concertId;
      ticketsRegister[nextTicketNumber].amountPaid = msg.value;
      ticketsRegister[nextTicketNumber].owner = msg.sender;
      ticketsRegister[nextTicketNumber].isAvailable = true;
      nextTicketNumber +=1;
    }
	
	function transferTicket(uint256 _ticketId, address payable _newOwner) public {
		require(ticketsRegister[_ticketId].owner == msg.sender);
		ticketsRegister[_ticketId].owner = _newOwner;
	}
	
	function cashOutConcert(uint256 _concertId, address payable _cashOutAddress) public {
		// On verifie que c'est bien l'artiste du concert qui veut recuperer l'argent et que le concert a bien ete effectuee
		uint256 artistIdConcert = concertsRegister[_concertId].artistId;
		address payable adressOwnerArtist = artistsRegister[artistIdConcert].owner;
		require(adressOwnerArtist == msg.sender);
		require(concertsRegister[_concertId].concertDate < now);
		
		// Maintenant on recupere l'argent en utilisant la fonction .transfer (<address payable>.transfer(uint256 amount))
		uint256 totalMoney = concertsRegister[_concertId].totalMoneyCollected;
		uint256 venueIdConcert = concertsRegister[_concertId].venueId;
		uint256 comissionVenue = venuesRegister[venueIdConcert].standardComission / 10000;
		// Venue get a certain percentage of the ticket price : comission / 10 000
		uint256 venueShare = totalMoney * comissionVenue;
        uint256 artistShare = totalMoney - venueShare;
		
		_cashOutAddress.transfer(artistShare);
		venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venueShare);
		
		// Le concert est termine
		artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold += concertsRegister[_concertId].totalSoldTicket;
		delete concertsRegister[_concertId];
	}
	
	function offerTicketForSale(uint256 _ticketId, uint256 _salePrice) public {
		require(ticketsRegister[_ticketId].owner == msg.sender);
		// Il faut que le prix du ticket soit superieur au prix de revente
		uint256 ticketIdFromConcertId = ticketsRegister[_ticketId].concertId;
		require(concertsRegister[ticketIdFromConcertId].ticketPrice > _salePrice);
		// Le ticket est il disponible ou a t il deja ete utilise
		require(ticketsRegister[_ticketId].isAvailable == true);
		
		ticketsRegister[_ticketId].isAvailableForSale = true;
		ticketsRegister[_ticketId].isAvailable = true;
		ticketsRegister[_ticketId].salePrice = _salePrice;
	}
	
	function buySecondHandTicket(uint256 _ticketId) public payable {
		require(msg.value >= ticketsRegister[_ticketId].salePrice);
		require(ticketsRegister[_ticketId].isAvailable == true);
		require(ticketsRegister[_ticketId].isAvailableForSale == true);
		
		// On fait le transfert d'argent au proprietaire du billet
		ticketsRegister[_ticketId].owner.transfer(msg.value);
		// On change le nom du ticket pour le nom du nouveau proprietaire
		ticketsRegister[_ticketId].owner = msg.sender;
	}
}
