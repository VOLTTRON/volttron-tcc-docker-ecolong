from communication import *
from utils         import load_json, select_payload, create_json_file


# TODO: this value is should be the supply data
supply_data = 10

print("Broadcast inline message")

# create a jason file containing supply data
create_json_file(supply_data)

# select payload (data.json)
payload = select_payload("data")

# broadcast data
res = ff_post(payload)

# print out the response
print(res.text)
