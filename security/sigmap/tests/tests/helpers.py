"""
Helpers for tests

Purposes:
- Handles custom error messages 
- Handles "(unknown)" events which are not properly handled by Brownie

"""

from eth_abi import encode_single
import re
from brownie import (
    # Brownie helpers
    web3,
)

###########################
##### Revert Messages #####
###########################

# Custom error message with or without parameter(s)
# If the error has no parameter, you can either include the brackets or not
# NOTE: It is not battle tested, so if you find a bug, please report it
"""
Examples:
with reverts(custom_error("RewardAlreadyInitialized")):
with reverts(custom_error("InvalidPoolStatus(bool,bool)", [False, True])):
with reverts(custom_error("InvalidMaxStakeAmount(uint256)", max_operator_stake_amount_new)):
"""
def custom_error(error_name, var_values=None):
    try:
        # we search using regex and make sure we only have one match
        var_types = re.findall(r'\(.*?\)', error_name)[0]
        # Remove brackets if it only has one variable
        if "," not in var_types:
            var_types = var_types[1:-1]
    except:
        # This has no brackets, so we add them
        # We do this to maintain compatibility with the old custom_error
        error_name = error_name + "()"

    sig = web3.solidityKeccak(["string"], [error_name])[:4]

    if var_values is None:
        return "typed error: " + str(web3.toHex(sig))
    else:
        return "typed error: " + str(web3.toHex(sig)) + str(
            web3.toHex(encode_single(var_types, var_values))
        )[2:]


##########################
##### Unknown Events #####
##########################


# Returns both event header and data
# When dealing with Libraries, Brownie cannot catch the exact event name and data so it will return "(unknown)" as the event name
# The function can handle zero or more parameters
"""
Example:
assert tx.events["(unknown)"] == error_unknown("RewardInitialized(uint256,uint256,uint256,uint256)", [initial_reward_rate, reward_amount, s_reward.start_timestamp, s_reward.end_timestamp])
assert tx.events["(unknown)"] == event_unknown("PoolOpened()", formatted=True)
"""
def event_unknown(event_name="", var_values=None, formatted=True):
    topic1 = web3.keccak(text=event_name).hex()

    if var_values is None:
        data = web3.toHex(bytes(0))
    else:
        # we search using regex and make sure we only have one match
        var_types = re.findall(r'\(.*?\)', event_name)[0]

        # Remove brackets if it only has one variable
        if "," not in var_types:
            var_types = var_types[1:-1]

        data = web3.toHex(encode_single(var_types, var_values))

    if formatted:
        return {
            "topic1": topic1,
            "data": data,
        }
    else:
        return topic1, data
