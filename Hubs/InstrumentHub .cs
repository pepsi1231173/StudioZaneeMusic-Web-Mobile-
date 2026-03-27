    using Microsoft.AspNetCore.SignalR;
    using System.Threading.Tasks;

    namespace DuAnBai3.Hubs
    {
        public class InstrumentHub : Hub
        {
            // 🎸 Gửi khi trạng thái thuê thay đổi
            public async Task NotifyRentalStatusChanged(int rentalId, string newStatus)
            {
                await Clients.All.SendAsync("RentalStatusChanged", rentalId, newStatus);
            }

            // 🔧 Gửi khi bảo trì nhạc cụ thay đổi
            public async Task NotifyInstrumentMaintenanceUpdated(List<int> instrumentIds)
            {
                await Clients.All.SendAsync("InstrumentMaintenanceUpdated", instrumentIds);
            }
        }

    }
