package Carrier.CarriOn.User;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserUpdateRequest {
    private String name;
    private String password;
    private String profileImage;
}
