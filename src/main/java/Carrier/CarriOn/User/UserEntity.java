package Carrier.CarriOn.User;

import Carrier.CarriOn.Chat.ChatRoom;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Getter
@Setter
@Table(name = "user_table")
public class UserEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    @Column(unique = true, nullable = false)
    private String loginId;

    @Column(nullable = false)
    private String password;

    @Column(unique = true, nullable = false)
    private String name;

    @Lob
    @Column(nullable = true)
    private byte[] profileImage;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "friendships",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "friend_id")
    )
    private Set<UserEntity> friends = new HashSet<>();

    @ManyToMany(mappedBy = "participants")
    private List<ChatRoom> chatRooms;

    public UserEntity() {
    }

    // 매개변수가 있는 생성자
    public UserEntity(String loginId, String password, String name, byte[] profileImage) {
        this.loginId = loginId;
        this.password = password;
        this.name = name;
        this.profileImage = profileImage;
    }

    public UserEntity(String name, String password) {
        this.name = name;
        this.password = password;
    }
}