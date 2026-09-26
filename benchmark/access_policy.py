from support.comparison import run_comparison


def main(requests: int) -> int:
    principals = [0] * requests
    resources = [0] * requests
    state = 123456789
    for i in range(requests):
        state = (state * 1103515245 + 12345) & 0x7fffffff
        principals[i] = state
        state = (state * 1103515245 + 12345) & 0x7fffffff
        resources[i] = state

    now = 1120
    allowed_count = 0
    review_count = 0
    denied_count = 0
    policy_score = 0
    for i in range(requests):
        principal = principals[i]
        resource = resources[i]
        tenant = (principal >> 8) & 7
        resource_tenant = (tenant + 1) & 7 if ((resource >> 5) & 3) == 0 else tenant
        user = (principal >> 11) & 127
        owner = user if ((resource >> 3) & 7) == 0 else (resource >> 11) & 127
        role = (principal >> 18) & 3
        risk = (principal >> 20) % 100

        same_tenant = tenant == resource_tenant
        owns_document = user == owner
        role_grants = role >= 2 or (role == 1 and owns_document)
        verified = (resource & 0x08000000) != 0
        suspended = (resource & 0x70000000) == 0x70000000
        active = now < 1000 + ((resource >> 8) & 255)
        safe = risk < 65 or (verified and risk < 80)
        allow = same_tenant and active and role_grants and safe and not suspended
        review = (same_tenant and active and role_grants and not suspended
                  and not allow and (verified or risk < 90))

        if allow:
            allowed_count += 1
            policy_score += 200 - risk
        elif review:
            review_count += 1
            policy_score += 100 - risk
        else:
            denied_count += 1
            policy_score -= risk + 1

    return (policy_score + allowed_count * 1000003
            + review_count * 1009 + denied_count)


if __name__ == '__main__':
    run_comparison(
        'access_policy', main, unit='request',
        iterations=200000, warmup_iterations=1000,
    )
