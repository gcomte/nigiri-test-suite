# nigiri-test-suite
Some highly customized helper tools for [Nigiri](https://github.com/vulpemventures/nigiri)  
It has been created with very specific use cases in mind and may not be useful to you.  
The main focus is on simulating a high fee rate environment.

## Usage
⚠️ **Caution:** Some commands reset your entire Nigiri
 - `make init`: Reset nigiri, start all containers, open a new channel between two CLN nodes, start flooding the mempool
 - `make restart`: Same as `make init`, but without resetting nigiri
 - `make mine`: Wait for the next block to be completely full, then mine it. Hopefully *without* confirming the closing TX.
 - `make close_rich`: Unilateraly close the channel from the CLN node that opened the channel and has on-chain funds available.
 - `make close_poor`: Unilateraly close the channel from the passive CLN node that did *not* open the channel and does *not* have any on-chain funds available either.

