import "@stdlib/deploy";
import "@stdlib/ownable";

// 클레임 메시지 정의
message NewClaim {
    claimType: String;
}

// 클레임 응답 메시지 정의
message NewClaimResponse {
    claimCount: Int as uint256;
}

// 구매 메시지 정의
message NewPurchase {
    itemId: Int;
    amount: Int as coins;//total Price of the items (TON)
}

// 구매 응답 메시지 정의
message NewPurchaseResponse {
    seqno: Int as uint256;
}

message Withdraw {
    amount: Int as coins;
}

// 부모 컨트랙트
contract CatTestParentContract with Deployable, Ownable {
    owner: Address;
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    const MinTonForGas: Int = ton("0.0002"); // estimated minimal gas fee
    userContracts: map<Address, Address>; // maps user address to their child contract
    userClaimCounts: map<Address, Int as uint256>; // maps user address to their claim count

    init() {
        self.owner = sender(); // set the owner as the deployer
    }

    
    // 유저 등록 및 자식 컨트랙트 배포
    fun registerUser(userAddress: Address) {
        let init: StateInit = initOf CatTestChildContract(myAddress(), userAddress);
        send(SendParameters{
            to: contractAddress(init),
            value: self.MinTonForGas,
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data
        });
        self.userContracts.set(userAddress, contractAddress(init));
        self.userClaimCounts.set(userAddress, 0); // initialize claim count to 0
    }

    // 새로운 클레임 추가
    receive(msg: NewClaim) {
        let userAddress: Address = sender();
        if (self.userClaimCounts.get(userAddress) == null) {
            self.userClaimCounts.set(userAddress, 0); // initialize claim count to 0 if not registered
        }

        let claimCount: Int = self.userClaimCounts.get(userAddress)!!;
        claimCount = claimCount + 1;
        self.userClaimCounts.set(userAddress, claimCount);
        self.reply(NewClaimResponse{claimCount: claimCount}.toCell());
    }

    // 새로운 구매 추가
    receive(msg: NewPurchase) {
        let userAddress: Address = sender();
        let userContract: Address? = self.userContracts.get(userAddress);
        if (self.userContracts.get(userAddress) == null) {
            self.registerUser(userAddress);
            userContract = self.userContracts.get(userAddress);
        }
        send(SendParameters{
            to: userContract!!,
            body: InternalNewPurchase{itemId: msg.itemId, amount: msg.amount}.toCell(),
            value: self.MinTonForGas,
            mode: SendIgnoreErrors
        });

        if (self.userClaimCounts.get(userAddress) == null) {
            self.userClaimCounts.set(userAddress, 0); // initialize claim count to 0 if not registered
        }

        let claimCount: Int = self.userClaimCounts.get(userAddress)!!;
        claimCount = claimCount + 1;
        self.userClaimCounts.set(userAddress, claimCount);
        self.reply(NewPurchaseResponse{seqno: self.userClaimCounts.get(userAddress)!!}.toCell());
    }

    get fun userContract(userAddress: Address): Address? {
        return self.userContracts.get(userAddress);
    }

    //Claim횟수(+Purchase 횟수)
    get fun userClaimCount(userAddress: Address): Int? {
        return self.userClaimCounts.get(userAddress);
    }

    // this will withdraw the entire balance of the contract and leave 0
    receive("withdraw all") {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    // this will withdraw the entire balance but leave 0.01 for storage rent costs
    receive("withdraw safe") {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }
 
    get fun balance(): String {
        return myBalance().toCoinsString();
    }
}

//////////////자식 컨트랙트////////////////////
// 내부 클레임 설정 메시지
message InternalNewClaim {
    claimType: String;
}

// 내부 구매 설정 메시지
message InternalNewPurchase {
    itemId: Int;
    amount: Int as coins;
}

// 구매 세부 정보 구조체
struct PurchaseDetails {
    itemId: Int;
    amount: Int as coins;
    timestamp: Int as uint64;
}

// 유저의 구매 기록을 관리하는 자식 컨트랙트
contract CatTestChildContract {
    parent: Address;
    user: Address;
    numPurchases: Int as uint256 = 0;
    purchases: map<Int, PurchaseDetails>;

    init(parent: Address, user: Address) {
        self.parent = parent;
        self.user = user;
    }

    receive(msg: InternalNewPurchase) {
        require(sender() == self.parent, "Parent only");

        self.numPurchases = self.numPurchases + 1;
        let newPurchase: PurchaseDetails = PurchaseDetails{
            itemId: msg.itemId,
            amount: msg.amount,
            timestamp: now()
        };
        self.purchases.set(self.numPurchases, newPurchase);
    }

    // 구매 세부 정보 반환 함수
    get fun purchaseDetails(seqno: Int): PurchaseDetails? {
        return self.purchases.get(seqno);
    }

    get fun numPurchases(): Int {
        return self.numPurchases;
    }
}