import { useNavigate } from 'react-router-dom'
import { Settings, TrendingUp } from 'lucide-react'
import { PageHeader } from '../ui/PageHeader'
import { PageContainer } from '../ui/PageContainer'
import { Card } from '../ui/Card'
import { NavListRow } from '../ui/NavListRow'

export default function MoreView() {
  const navigate = useNavigate()

  return (
    <PageContainer width="narrow" stackClassName="space-y-4">
      <PageHeader title="More" subtitle="Shortcuts and settings" />

      <Card padding={false} className="overflow-hidden divide-y divide-[var(--border)]">
        <NavListRow
          icon={<TrendingUp size={20} />}
          label="Progress"
          sub="Accuracy and breakdowns"
          onClick={() => navigate('/stats')}
        />
        <NavListRow
          icon={<Settings size={20} />}
          label="Settings"
          sub="Account, appearance, font size, and data"
          onClick={() => navigate('/settings')}
        />
      </Card>
    </PageContainer>
  )
}
