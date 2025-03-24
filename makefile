SHELL := /bin/bash

deploy_sepolia:
	source .env && forge script deploy --rpc-url $$sepolia_url --etherscan-api-key $$sepolia_api --verify --account pk --sender $(sender) --broadcast


deploy_arb:
	source .env && forge script deploy --rpc-url $$arb_url --etherscan-api-key $$arb_api --verify --account pk --sender $(sender) --broadcast

deploy_mumbai:
	source .env && forge script deploy --rpc-url $$mumbai_url --etherscan-api-key $$mumbai_api --verify --account pk --sender $(sender) --broadcast

deploy_sepolia_local:
	source .env && forge script deploy --rpc-url $$sepolia_url  --sender $(sender) --broadcast

deploy_arb_local:
	source .env && forge script deploy --rpc-url $$arb_url  --sender $(sender) --broadcast

deploy_mumbai_local:
	source .env && forge script deploy --rpc-url $$mumbai_url  --sender $(sender) --broadcast

config_sepolia:
	source .env && forge script deploy --sig "config()" --rpc-url $$sepolia_url   --account pk --sender $(sender) --broadcast

config_arb:
	source .env && forge script deploy --sig "config()" --rpc-url $$arb_url   --account pk --sender $(sender) --broadcast

config_mumbai:
	source .env && forge script deploy --sig "config()" --rpc-url $$mumbai_url   --account pk --sender $(sender) --broadcast

config_sepolia_local:
	source .env && forge script deploy --sig "config()" --rpc-url $$sepolia_url --sender $(sender)

config_arb_local:
	source .env && forge script deploy --sig "config()" --rpc-url $$arb_url --sender $(sender)

config_mumbai_local:
	source .env && forge script deploy --sig "config()" --rpc-url $$mumbai_url --sender $(sender)

wrap_and_send:
	source .env && forge script deploy --sig "wrapAndSend()" --rpc-url $$arb_url   --account pk --sender $(sender) --broadcast



   
