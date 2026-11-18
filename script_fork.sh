set -e
RPC=https://bsc-dataseed.bnbchain.org
# start anvil fork
anvil --fork-url $RPC --port 8791 --silent &
ANVIL=$!
sleep 4
DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
BYTECODE=$(python3 -c "import json;print(json.load(open('out/AgentTipJar.sol/AgentTipJar.json'))['bytecode']['object'])")
ARGS=$(cast abi-encode "constructor(address)" 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F | sed 's/0x//')
ADDR=$(cast send --rpc-url http://127.0.0.1:8791 --private-key $PK --create ${BYTECODE}${ARGS} --json | python3 -c "import json,sys;print(json.load(sys.stdin)['contractAddress'])")
echo "deployed(fork): $ADDR"
USER=0x31F4C889cf5adb5b456E57AC63991952C0f1Ee67
echo -n "isAgent(user): "; cast call $ADDR "isAgent(address)(bool)" $USER --rpc-url http://127.0.0.1:8791
echo -n "isAgent(random 0x...dEaD): "; cast call $ADDR "isAgent(address)(bool)" 0x000000000000000000000000000000000000dEaD --rpc-url http://127.0.0.1:8791
# fund user on fork and tip from user to sufa.ai wallet (also an Agent ID holder? check)
cast rpc anvil_setBalance $USER 0xde0b6b3a7640000 --rpc-url http://127.0.0.1:8791 >/dev/null
SUFA=0x79d1b7E886056BCCa3e20F21c2078Ce994bAF450
echo -n "isAgent(sufa): "; cast call $ADDR "isAgent(address)(bool)" $SUFA --rpc-url http://127.0.0.1:8791
cast rpc anvil_impersonateAccount $USER --rpc-url http://127.0.0.1:8791 >/dev/null
cast send $ADDR "tip(address)" $SUFA --value 0.01ether --from $USER --unlocked --rpc-url http://127.0.0.1:8791 >/dev/null
echo -n "totalTips: "; cast call $ADDR "totalTips()(uint256)" --rpc-url http://127.0.0.1:8791
echo -n "uniqueAgents: "; cast call $ADDR "uniqueAgents()(uint256)" --rpc-url http://127.0.0.1:8791
echo -n "sufa received total: "; cast call $ADDR "tipsReceivedTotal(address)(uint256)" $SUFA --rpc-url http://127.0.0.1:8791
kill $ANVIL
