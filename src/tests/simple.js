import http from "k6/http";
import { sleep } from "k6";
import { check } from "k6";
export const options = {
  scenarios: {
    jwt_sqlite_stress: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "5s", target: 10 }, // Ramp to 10 VUs
        { duration: "10s", target: 50 }, // Ramp to 50 VUs
        { duration: "30s", target: 100 }, // Ramp to 100 VUs
        { duration: "5s", target: 0 }, // Ramp down
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<1000"], // 95% under 1s
    http_req_failed: ["rate<0.05"], // Error rate under 5% (more realistic for SQLite)
  },
};
