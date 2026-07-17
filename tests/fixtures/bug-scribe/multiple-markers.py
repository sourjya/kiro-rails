# Module with multiple bugs found

def parse_response(data):
    # bug: TYPE_MISMATCH — response is nested object, not flat
    return data["result"]["items"]


def calculate_total(items):
    # bug: ROUTE_ORDERING — wildcard route catches this before specific
    total = sum(item.price for item in items)
    return total
