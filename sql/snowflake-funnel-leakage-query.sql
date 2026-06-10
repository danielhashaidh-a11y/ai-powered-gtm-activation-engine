snowflake query leads

Explanation of query


WITH user_base AS (
    SELECT
        h.email,
        h.first_name,
        h.last_name,
        h.company_name,
        h.created_at AS lead_created_at,
        h.utm_source,
        h.utm_medium,
        h.utm_campaign,
        h.utm_content,
        h.landing_page_url,
        h.referrer,

        z.industry,
        z.company_size,
        z.job_title,

        s.salesforce_lead_id,
        s.owner_id,
        s.lead_status

    FROM hubspot_contacts h
    LEFT JOIN zoominfo_enrichment z
        ON LOWER(h.email) = LOWER(z.email)
    LEFT JOIN salesforce_leads s
        ON LOWER(h.email) = LOWER(s.email)
),

posthog_summary AS (
    SELECT
        LOWER(person_email) AS email,

        MIN(CASE WHEN event = 'signup_completed' THEN timestamp END) AS signup_completed_at,
        MIN(CASE WHEN event = 'setup_completed' THEN timestamp END) AS setup_completed_at,
        MIN(CASE WHEN event = 'product_run_completed' THEN timestamp END) AS product_run_completed_at,
        MIN(CASE WHEN event = 'team_member_added' THEN timestamp END) AS team_member_added_at,

        COUNT_IF(event = '$pageview') AS pages_viewed,
        COUNT(DISTINCT session_id) AS visit_count,

        DATEDIFF('second', MIN(timestamp), MAX(timestamp)) AS time_on_site_seconds,

        MAX(CASE
            WHEN event = '$pageview'
             AND page_url ILIKE '%pricing%'
            THEN TRUE ELSE FALSE
        END) AS pricing_page_viewed,

        MAX(CASE
            WHEN event = '$pageview'
             AND page_url ILIKE '%demo%'
            THEN TRUE ELSE FALSE
        END) AS demo_page_viewed,

        MAX(CASE
            WHEN event = '$pageview'
             AND page_url ILIKE '%signup%'
            THEN TRUE ELSE FALSE
        END) AS signup_page_viewed,

        MAX_BY(page_url, timestamp) AS last_page_viewed

    FROM posthog_events
    GROUP BY LOWER(person_email)
),

final_profile AS (
    SELECT
        u.email,
        u.first_name,
        u.last_name,
        u.company_name,
        u.industry,
        u.company_size,
        u.job_title,
        u.salesforce_lead_id,
        u.owner_id,
        u.lead_status,

        u.utm_source,
        u.utm_medium,
        u.utm_campaign,
        u.utm_content,
        u.landing_page_url,
        u.referrer,

        p.last_page_viewed,
        COALESCE(p.pages_viewed, 0) AS pages_viewed,
        COALESCE(p.visit_count, 0) AS visit_count,
        COALESCE(p.time_on_site_seconds, 0) AS time_on_site_seconds,
        COALESCE(p.pricing_page_viewed, FALSE) AS pricing_page_viewed,
        COALESCE(p.demo_page_viewed, FALSE) AS demo_page_viewed,
        COALESCE(p.signup_page_viewed, FALSE) AS signup_page_viewed,

        p.signup_completed_at,
        p.setup_completed_at,
        p.product_run_completed_at,
        p.team_member_added_at,

        CASE
            WHEN p.signup_completed_at IS NULL THEN 'lead_not_signed_up'
            WHEN p.setup_completed_at IS NULL THEN 'setup_not_completed'
            WHEN p.product_run_completed_at IS NULL THEN 'product_run_not_completed'
            WHEN p.team_member_added_at IS NULL THEN 'team_invite_missing'
            ELSE 'healthy'
        END AS stuck_stage,

        CASE
            WHEN p.signup_completed_at IS NOT NULL
             AND p.setup_completed_at IS NULL
                THEN DATEDIFF('day', p.signup_completed_at, CURRENT_TIMESTAMP)

            WHEN p.setup_completed_at IS NOT NULL
             AND p.product_run_completed_at IS NULL
                THEN DATEDIFF('day', p.setup_completed_at, CURRENT_TIMESTAMP)

            WHEN p.product_run_completed_at IS NOT NULL
             AND p.team_member_added_at IS NULL
                THEN DATEDIFF('day', p.product_run_completed_at, CURRENT_TIMESTAMP)

            ELSE 0
        END AS days_stuck,

        LEAST(100,
            CASE WHEN COALESCE(p.pricing_page_viewed, FALSE) THEN 15 ELSE 0 END +
            CASE WHEN COALESCE(p.demo_page_viewed, FALSE) THEN 15 ELSE 0 END +
            CASE WHEN COALESCE(p.signup_page_viewed, FALSE) THEN 10 ELSE 0 END +
            CASE WHEN COALESCE(p.pages_viewed, 0) >= 5 THEN 15 ELSE 0 END +
            CASE WHEN COALESCE(p.visit_count, 0) >= 3 THEN 15 ELSE 0 END +
            CASE WHEN COALESCE(p.time_on_site_seconds, 0) >= 300 THEN 15 ELSE 0 END +
            CASE WHEN p.product_run_completed_at IS NOT NULL THEN 25 ELSE 0 END
        ) AS engagement_score,

        LEAST(100,
            CASE
                WHEN p.signup_completed_at IS NULL THEN 20
                WHEN p.setup_completed_at IS NULL THEN 35
                WHEN p.product_run_completed_at IS NULL THEN 30
                WHEN p.team_member_added_at IS NULL THEN 45
                ELSE 0
            END +
            CASE
                WHEN
                    CASE
                        WHEN p.signup_completed_at IS NOT NULL
                         AND p.setup_completed_at IS NULL
                            THEN DATEDIFF('day', p.signup_completed_at, CURRENT_TIMESTAMP)

                        WHEN p.setup_completed_at IS NOT NULL
                         AND p.product_run_completed_at IS NULL
                            THEN DATEDIFF('day', p.setup_completed_at, CURRENT_TIMESTAMP)

                        WHEN p.product_run_completed_at IS NOT NULL
                         AND p.team_member_added_at IS NULL
                            THEN DATEDIFF('day', p.product_run_completed_at, CURRENT_TIMESTAMP)

                        ELSE 0
                    END >= 3
                THEN 15 ELSE 0
            END +
            CASE
                WHEN
                    CASE
                        WHEN p.signup_completed_at IS NOT NULL
                         AND p.setup_completed_at IS NULL
                            THEN DATEDIFF('day', p.signup_completed_at, CURRENT_TIMESTAMP)

                        WHEN p.setup_completed_at IS NOT NULL
                         AND p.product_run_completed_at IS NULL
                            THEN DATEDIFF('day', p.setup_completed_at, CURRENT_TIMESTAMP)

                        WHEN p.product_run_completed_at IS NOT NULL
                         AND p.team_member_added_at IS NULL
                            THEN DATEDIFF('day', p.product_run_completed_at, CURRENT_TIMESTAMP)

                        ELSE 0
                    END >= 7
                THEN 25 ELSE 0
            END +
            CASE WHEN COALESCE(p.pricing_page_viewed, FALSE) THEN 10 ELSE 0 END +
            CASE WHEN COALESCE(p.visit_count, 0) >= 3 THEN 10 ELSE 0 END
        ) AS leakage_score

    FROM user_base u
    LEFT JOIN posthog_summary p
        ON LOWER(u.email) = p.email
)

SELECT
    *,

    CASE
        WHEN leakage_score <= 30 THEN 'healthy'
        WHEN leakage_score BETWEEN 31 AND 70 THEN 'warning'
        ELSE 'high_risk'
    END AS risk_level,

    CASE
        WHEN stuck_stage = 'lead_not_signed_up'
            THEN 'send_signup_conversion_email'
        WHEN stuck_stage = 'setup_not_completed'
            THEN 'send_setup_recovery_email'
        WHEN stuck_stage = 'product_run_not_completed'
            THEN 'send_product_activation_email'
        WHEN stuck_stage = 'team_invite_missing'
            THEN 'send_team_invite_email_and_create_salesforce_task'
        ELSE 'no_action'
    END AS suggested_action,

    CASE
        WHEN leakage_score >= 70 THEN TRUE
        WHEN company_size >= 1000 THEN TRUE
        WHEN engagement_score >= 80 AND leakage_score >= 50 THEN TRUE
        ELSE FALSE
    END AS send_to_ai

FROM final_profile
WHERE stuck_stage <> 'healthy'
  AND leakage_score >= 40
ORDER BY leakage_score DESC, engagement_score DESC;
