using System.Collections.Generic;

namespace DuAnBai3.Models
{
    public class ServiceHistoryModel
    {
        public List<Booking> RoomBookings { get; set; }
        public List<InstrumentRentals> InstrumentRentals { get; set; }
        public List<RecordingBooking> RecordingBookings { get; set; }
        public List<MusicRequest> MusicRequests { get; set; }
    }
}