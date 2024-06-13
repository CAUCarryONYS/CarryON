package Carrier.CarriOn.Friend;

import Carrier.CarriOn.User.UserEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "friendships")
@Getter
@Setter
public class Friendship {
    @EmbeddedId
    private FriendshipId id;

    @ManyToOne
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private UserEntity user;

    @ManyToOne
    @MapsId("friendId")
    @JoinColumn(name = "friend_id", insertable = false, updatable = false)
    private UserEntity friend;

    @Enumerated(EnumType.STRING)
    private FriendshipStatus status;
}