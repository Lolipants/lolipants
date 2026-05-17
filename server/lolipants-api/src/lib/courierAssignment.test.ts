import { describe, expect, it } from "vitest";
import { pickCourierForDelivery } from "./courierAssignment";

type CourierUser = { id: string; name: string; role: string; banned_at?: string | null };
type OrderRow = {
  id: string;
  courier_id: string | null;
  status: string;
};

function mockCourierDb(users: CourierUser[], orders: OrderRow[]) {
  return {
    prepare(sql: string) {
      return {
        async all<T>() {
          if (
            sql.includes("FROM users u") &&
            sql.includes("role = 'delivery'")
          ) {
            const deliveryUsers = users.filter((u) => u.role === "delivery");
            const rows = deliveryUsers
              .filter((u) => !u.banned_at)
              .map((u) => {
                const active_count = orders.filter(
                  (o) =>
                    o.courier_id === u.id &&
                    (o.status === "ready_to_ship" ||
                      o.status === "out_for_delivery"),
                ).length;
                return { id: u.id, name: u.name, active_count };
              })
              .sort((a, b) =>
                a.active_count !== b.active_count
                  ? a.active_count - b.active_count
                  : a.id.localeCompare(b.id),
              );
            return { results: rows as T[] };
          }
          return { results: [] as T[] };
        },
      };
    },
  } as unknown as D1Database;
}

describe("pickCourierForDelivery", () => {
  it("returns null when no delivery users exist", async () => {
    const picked = await pickCourierForDelivery(
      mockCourierDb([], []),
    );
    expect(picked).toBeNull();
  });

  it("prefers the courier with fewer active deliveries", async () => {
    const users: CourierUser[] = [
      { id: "c-busy", name: "Busy", role: "delivery" },
      { id: "c-free", name: "Free", role: "delivery" },
    ];
    const orders: OrderRow[] = [
      { id: "o1", courier_id: "c-busy", status: "out_for_delivery" },
      { id: "o2", courier_id: "c-busy", status: "ready_to_ship" },
    ];
    const picked = await pickCourierForDelivery(mockCourierDb(users, orders));
    expect(picked?.courierId).toBe("c-free");
    expect(picked?.courierName).toBe("Free");
  });
});
