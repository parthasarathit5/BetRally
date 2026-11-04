from decimal import Decimal, ROUND_HALF_UP


def calculate_mines_multiplier(total_tiles: int, mine_count: int, revealed_count: int, house_edge: float = 0.03) -> Decimal:
    """
    Provably fair multiplier formula for Mines game:
    M = (1 - house_edge) * Product( (total - i) / (safe_total - i) ) for i from 0 to revealed_count-1
    """
    if revealed_count <= 0:
        return Decimal("1.00")

    safe_tiles = total_tiles - mine_count
    if revealed_count > safe_tiles:
        revealed_count = safe_tiles

    multiplier = 1.0
    for i in range(revealed_count):
        prob = (safe_tiles - i) / (total_tiles - i)
        multiplier *= (1.0 / prob)

    # Apply house edge (3%)
    final_mult = multiplier * (1.0 - house_edge)
    if final_mult < 1.01:
        final_mult = 1.01

    return Decimal(str(final_mult)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

