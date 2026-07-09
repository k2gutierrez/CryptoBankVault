-include .env

.PHONY:; all test deploy

build :; forge build

test :; forge test

install :; forge install cyfrin/foundry-devops && forge install foundry-rs/forge-std && forge install openzeppelin/openzeppelin-contracts

deploy-cryptovaultandtoken-curtis :
	@forge script script/DeployBankAndToken.s.sol:DeployBankAndToken --rpc-url $(CURTIS_RPC_URL) --account defaultk2 --broadcast --verify --verifier blockscout --verifier-url "https://api.etherscan.io/v2/api?chainid=33111" -vvvv

deploy-cryptovaultandtoken-apechain :
	@forge script script/DeployBankAndToken.s.sol:DeployBankAndToken --rpc-url $(APECHAIN_RPC_URL) --account defaultk2 --broadcast  -vvvv

gluttons-verify-curtis :; forge verify-contract --constructor-args $(ENCODE_GLUTTONS_CONSTRUCTOR) $(GLUTTONS_CURTIS) src/Gluttons.sol:Gluttons --chain-id 33111 --verifier-url $(APESCAN_CURTIS_API_V2) --etherscan-api-key ${ETHERSCAN_API_KEY} # cast abi-encode "constructor(address,address)" 0xca067E20db2cDEF80D1c7130e5B71C42c0305529 0xbfAb062f38dd327c823e747C8Cd97853B7114241

gluttons-verify :; forge verify-contract --constructor-args $(ENCODE_GLUTTONS_CONSTRUCTOR) $(GLUTTONS) src/Gluttons.sol:Gluttons --chain-id 33139 --verifier-url $(APESCAN_API_V2) --etherscan-api-key ${ETHERSCAN_API_KEY} # cast abi-encode "constructor(address,address)" 0xca067E20db2cDEF80D1c7130e5B71C42c0305529 0xbfAb062f38dd327c823e747C8Cd97853B7114241

coverage-report :; forge coverage --report debug > coverage.txt

coverage :; forge coverage

set-traits-gluttons-curtis-EXAMPLE-FOR-CONTRACTS-USE-WITH-SCRIPS :
	@forge script script/Interactions.s.sol:SetTraits --rpc-url $(CURTIS_RPC_URL) --account defaultk2 --broadcast -vvvv

mint-gluttons-curtis :
	@forge script script/Interactions.s.sol:MintBasicNFT --rpc-url $(CURTIS_RPC_URL) --account defaultk2 --broadcast -vvv

mingle-balanceof :; cast call $(MINGLE_CURTIS) "balanceOf(address)(uint256)" 0xca067E20db2cDEF80D1c7130e5B71C42c0305529 --rpc-url $(CURTIS_RPC_URL) -vvvv