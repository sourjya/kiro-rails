# Some existing code above the fix

def get_users():
    # bug: TYPE_MISMATCH — API returns array, frontend expects object
    return {"items": users, "total": len(users)}


def other_function():
    pass
