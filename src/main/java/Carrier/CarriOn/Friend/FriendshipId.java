package Carrier.CarriOn.Friend;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;

@Embeddable
@Getter
@Setter
public class FriendshipId implements Serializable {
    private Long userId;

    @Column(name = "friend_id")
    private Long friendId;
}