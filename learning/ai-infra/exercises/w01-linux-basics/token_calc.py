import json
def total_tokens(token, request):
    return token * request


request_counts = [4,8,10]

for count in request_counts:
    print(total_tokens(158,count))

#config = {"tokens":256,"request":4}


with open("config.json","r",encoding="utf-8") as f:
    loaded = json.load(f)
config = loaded

print(total_tokens(config["tokens"],config["request"]))
