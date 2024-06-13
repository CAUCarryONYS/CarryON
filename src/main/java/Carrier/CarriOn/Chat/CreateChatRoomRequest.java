package Carrier.CarriOn.Chat;

import lombok.Getter;
import lombok.Setter;

import java.util.Set;

@Getter
@Setter
public class CreateChatRoomRequest {
    private String name;
    private Set<Long> memberIds;

    public CreateChatRoomRequest() {
    }

    public CreateChatRoomRequest(String name, Set<Long> memberIds) {
        this.name = name;
        this.memberIds = memberIds;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Set<Long> getMemberIds() {
        return memberIds;
    }

    public void setMemberIds(Set<Long> memberIds) {
        this.memberIds = memberIds;
    }
}
