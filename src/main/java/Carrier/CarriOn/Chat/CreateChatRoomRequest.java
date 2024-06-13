package Carrier.CarriOn.Chat;

import java.util.Set;

public class CreateChatRoomRequest {
    private String name;
    private Set<Long> memberIds;

    // 기본 생성자
    public CreateChatRoomRequest() {
    }

    // 매개변수가 있는 생성자
    public CreateChatRoomRequest(String name, Set<Long> memberIds) {
        this.name = name;
        this.memberIds = memberIds;
    }

    // Getter와 Setter
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
