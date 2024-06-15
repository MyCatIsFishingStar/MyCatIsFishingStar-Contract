import "@stdlib/deploy";

// 클레임 메시지 정의
message ClaimProcessed {
    claimType: String;
}

message Withdraw {
    amount: Int as coins;
}

// 유저의 클레임 구조체
struct UserClaim {
    address: Address;
    timestamp: Int as uint64;
    claimType: String;
    claimCount: Int as uint64;
}

contract CatTestContract with Deployable {
    claims: map<Address, UserClaim>;  // 모든 클레임을 순차적으로 저장하는 맵
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    deployer: Address;

    init() {
        self.deployer = sender();
    }

    receive(msg: ClaimProcessed) {
        let currentTime: Int = now();
        let senderAddress: Address = sender();

        // 기존 클레임 가져오기
        let existingClaimOpt: UserClaim? = self.claims.get(senderAddress);
        let newClaimCount: Int = 1;

        if (existingClaimOpt != null) {
            newClaimCount = existingClaimOpt!!.claimCount + 1;
        }

        // 새로운 클레임 생성
        let newClaim: UserClaim = UserClaim{
            address: senderAddress,
            timestamp: currentTime,
            claimType: msg.claimType,
            claimCount: newClaimCount
        };

        // 클레임을 맵에 추가
        self.claims.set(senderAddress, newClaim);

        // Notify the caller that the claim was processed
        self.notify("ClaimProcessed".asComment());
    }

    // 특정 인덱스의 클레임 반환 함수
    get fun getUserClaimCount(address: Address): UserClaim? {
        let claimOpt: UserClaim? = self.claims.get(address);
        if (claimOpt == null) {
            return null;
        }
        return claimOpt!!;
    }

    // this will withdraw the entire balance of the contract and leave 0
    receive("withdraw all") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    // this will withdraw the entire balance but leave 0.01 for storage rent costs
    receive("withdraw safe") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
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