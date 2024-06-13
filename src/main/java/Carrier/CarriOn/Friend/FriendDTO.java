package Carrier.CarriOn.Friend;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class FriendDTO {
    private Long id;
    private String name;
    private Long chatRoomId;
    private String profileImage;
}