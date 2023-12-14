init:
	./reset_everything.sh
	$(MAKE) restart
restart:
	./open_channel_between_cln.sh
	./simulate_high_feerate.sh
mine:
	./mine_block_when_full.sh
# Unilateral close initiated by a node that owns on-chain funds
close_rich: 
	docker stop cln2
	sleep 3
	./close_channel.sh cln
# Unilateral close initiated by a node that does not have any on-chain funds
close_poor:
	docker stop cln
	sleep 3
	./close_channel.sh cln2
