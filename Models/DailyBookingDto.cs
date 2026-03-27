using System.Text.Json.Serialization;

namespace DuAnBai3.Models
{
    public class DailyBookingDto
    {
        [JsonPropertyName("dailyNumber")]
        public int DailyNumber { get; set; }

        [JsonPropertyName("rentalDate")]
        public DateTime RentalDate { get; set; }
    }
}
