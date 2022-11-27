(SELECT
    COALESCE(cl.day, cv.day),
    COALESCE(cl.clicks, 0),
    COALESCE(cv.total_qty, 0),
    COALESCE(cv.approved_qty, 0),
    COALESCE(cv.hold_qty, 0),
    COALESCE(cv.rejected_qty, 0),
    COALESCE(
        case cl.clicks
            when 0 then 0  -- avoid divizion by zero
            else (100 * cv.total_qty / cl.clicks)
        end
        , 0) AS cr,
    COALESCE(cv.total_payout, 0),
    COALESCE(cv.approved_payout, 0),
    COALESCE(cv.hold_payout, 0),
    COALESCE(cv.rejected_payout, 0)
FROM
    (
        SELECT
            created_at::date AS day,
            count(*) AS clicks
        FROM tracker_click
        WHERE
            affiliate_id = {user_id}
            AND created_at between '{start_date}' AND '{end_date}'
            {offer_filter_clause}
        GROUP BY day
    ) AS cl
FULL OUTER JOIN
    (
        SELECT
            created_at::date AS day,
            count(*)                                       AS total_qty,
            count(*)    FILTER (WHERE status = 'approved') AS approved_qty,
            count(*)    FILTER (WHERE status = 'hold')     AS hold_qty,
            count(*)    FILTER (WHERE status = 'rejected') AS rejected_qty,
            sum(payout)                                    AS total_payout,
            sum(payout) FILTER (WHERE status = 'approved') AS approved_payout,
            sum(payout) FILTER (WHERE status = 'hold')     AS hold_payout,
            sum(payout) FILTER (WHERE status = 'rejected') AS rejected_payout
        FROM tracker_conversion
        WHERE
            affiliate_id = {user_id}
            AND created_at between '{start_date}' AND '{end_date}'
            {offer_filter_clause}
        GROUP BY day
    ) AS cv
ON cl.day = cv.day
ORDER BY cl.day DESC)
;